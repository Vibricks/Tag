-- Credit to Rookstun and the Ragdoll Solution: https://devforum.roblox.com/t/ragdoll-solution-r15customizable-ragdolls-for-use-with-layered-clothing/1738685
-- local RunService = game:GetService("RunService")

local TableUtils = require(script.Parent.Parent.TableUtils)
local Signal = require(script.Parent.Parent.Parent.Signal)
local Trove = require(script.Parent.Parent.Parent.Trove)

--[=[
	@class Ragdoll
	@__index Ragdoll
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Character Model
	The model this ragdoll corresponds to.
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Humanoid Humanoid
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop HumanoidRootPart BasePart
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop RagdollBegan Signal
	
	An signal fired when ragdoll physics has begun.

	```lua
		ragdoll.RagdollBegan:Connect(function()
			--Do something when ragdoll physics has begun
		end)
	```
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop RagdollEnded Signal
	A signal fired when ragdoll physics has ended.

	```lua
		ragdoll.RagdollEnded:Connect(function()
			--Do something when ragdoll physics has ended
		end)
	```
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Destroying Signal
	A signal fired when ragdoll:destroy() is called.
]=]
local Ragdoll = {}
Ragdoll.__index = Ragdoll

local LIMB_PHYSICAL_PROPERTIES = PhysicalProperties.new(5, 0.7, 0.5, 100, 100)
local ROOT_PART_PHYSICAL_PROPERTIES = PhysicalProperties.new(0, 0, 0, 0, 0)
-- local RAGDOLL_TIMEOUT_INTERVAL = 1.5
-- local RAGDOLL_TIMEOUT_DISTANCE_THRESHOLD = 2

local BALLSOCKETCONSTRAINT_TEMPLATE: BallSocketConstraint = Instance.new("BallSocketConstraint")
BALLSOCKETCONSTRAINT_TEMPLATE.Enabled = false
Ragdoll.BALLSOCKETCONSTRAINT_TEMPLATE = BALLSOCKETCONSTRAINT_TEMPLATE

local NOCOLLISIONCONSTRAINT_TEMPLATE: NoCollisionConstraint = Instance.new("NoCollisionConstraint")
NOCOLLISIONCONSTRAINT_TEMPLATE.Enabled = false
Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE = NOCOLLISIONCONSTRAINT_TEMPLATE

local LINEARVELOCITY_TEMPLATE: LinearVelocity = Instance.new("LinearVelocity")
LINEARVELOCITY_TEMPLATE.VectorVelocity = Vector3.new(0, 50, -8000) --At least any must be >0 to wake physics
LINEARVELOCITY_TEMPLATE.MaxForce = 8000
LINEARVELOCITY_TEMPLATE.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
LINEARVELOCITY_TEMPLATE.Enabled = false
Ragdoll.LINEARVELOCITY_TEMPLATE = LINEARVELOCITY_TEMPLATE

local ANGULARVELOCITY_TEMPLATE: AngularVelocity = Instance.new("AngularVelocity")
ANGULARVELOCITY_TEMPLATE.AngularVelocity = Vector3.new(0, 10, 0)
ANGULARVELOCITY_TEMPLATE.MaxTorque = 1000
ANGULARVELOCITY_TEMPLATE.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
ANGULARVELOCITY_TEMPLATE.ReactionTorqueEnabled = false
ANGULARVELOCITY_TEMPLATE.Enabled = false
Ragdoll.ANGULARVELOCITY_TEMPLATE = ANGULARVELOCITY_TEMPLATE

--@ignore
function Ragdoll.new(character: Model, blueprint)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false

	local trove = Trove.new()
	local constraintsFolder = trove:Add(Instance.new("Folder"))
	constraintsFolder.Name = "RagdollConstraints"
	local socketsFolder = Instance.new("Folder")
	socketsFolder.Name = "BallSocketConstraints"
	socketsFolder.Parent = constraintsFolder
	local noCollisionsfolder = Instance.new("Folder")
	noCollisionsfolder.Name = "NoCollisionConstraints"
	noCollisionsfolder.Parent = constraintsFolder
	constraintsFolder.Parent = character

	character:SetAttribute("Ragdolled", false)
	local children = character:GetChildren()

	local self = setmetatable({
		Character = character,
		Humanoid = humanoid,
		Animator = humanoid:WaitForChild("Animator"),
		HumanoidRootPart = character:WaitForChild("HumanoidRootPart"),
		RagdollBegan = trove:Construct(Signal),
		RagdollEnded = trove:Construct(Signal),
		Collapsed = trove:Construct(Signal),
		Destroying = trove:Construct(Signal),
		_collapsed = false,
		_frozen = false,
		_ragdolled = false,
		_trove = trove,
		_constraintsFolder = constraintsFolder,
		_socketFolder = socketsFolder,
		_noCollisionConstraintFolder = noCollisionsfolder,
		_sockets = table.create(blueprint.numLimbs),
		_noCollisionConstraints = table.create(blueprint.numLimbs),
		_originalSettings = {},
		_limbs = TableUtils.filter(children, function(limb)
			return limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart"
		end),
		_accessoryHandles = TableUtils.map(
			TableUtils.filter(children, function(accessory)
				return accessory:IsA("Accessory")
			end),
			function(accessory: Accessory)
				return accessory:FindFirstChild("Handle")
			end
		),
		_motor6Ds = TableUtils.filter(character:GetDescendants(), function(motor)
			return motor:IsA("Motor6D")
		end),
	}, Ragdoll)

	Ragdoll._recordOriginalSettings(self)

	Ragdoll._setupLimbs(self, blueprint)

	self._lowDetailModeSockets = if blueprint.lowDetailModeLimbs
		then TableUtils.filter(self._sockets, function(socket: BallSocketConstraint)
			return blueprint.lowDetailModeLimbs[socket.Name]
		end)
		else self._sockets

	self._lowDetailMotor6Ds = TableUtils.filter(self._motor6Ds, function(motor: Motor6D)
		return blueprint.lowDetailModeLimbs[(motor.Part1 :: BasePart).Name]
	end)

	self.RagdollBegan:Connect(function()
		character:SetAttribute("Ragdolled", true)
	end)

	self.RagdollEnded:Connect(function()
		character:SetAttribute("Ragdolled", false)
	end)

	blueprint.finalTouches(self)

	return self
end

--[=[
	@private
	@param ragdoll Ragdoll
	Records the original settings of the BaseParts, Motor6Ds, Accessory Handles, and Humanoid of the ragdoll.
]=]
function Ragdoll._recordOriginalSettings(ragdoll)
	local function recordSetting(object: Instance, record)
		if ragdoll._originalSettings[object] then
			for key, value in record do
				ragdoll._originalSettings[object][key] = value
			end
		else
			ragdoll._originalSettings[object] = record
		end
	end

	recordSetting(
		ragdoll.Humanoid,
		{ WalkSpeed = ragdoll.Humanoid.WalkSpeed, AutoRotate = ragdoll.Humanoid.AutoRotate }
	)
	recordSetting(ragdoll.HumanoidRootPart, {
		Anchored = ragdoll.HumanoidRootPart.Anchored,
		CanCollide = ragdoll.HumanoidRootPart.CanCollide,
		CustomPhysicalProperties = ragdoll.HumanoidRootPart.CustomPhysicalProperties,
	})

	for _, limb in ragdoll._limbs do
		recordSetting(limb, {
			Anchored = limb.Anchored,
			CanCollide = limb.CanCollide,
			CustomPhysicalProperties = limb.CustomPhysicalProperties,
		})
	end

	for _, handle in ragdoll._accessoryHandles do
		recordSetting(handle, {
			CanCollide = handle.CanCollide,
			CanTouch = handle.CanTouch,
			Massless = handle.Massless,
		})
	end

	for _, motor6D in ragdoll._motor6Ds do
		recordSetting(motor6D, { Enabled = motor6D.Enabled })
	end
end

--[=[
	@private
	@param ragdoll Ragdoll
	@param sourceLimb BasePart
	@param affectedLimb BasePart
	@param cframe0 CFrame
	@param cframe1 CFrame
	@param blueprint Blueprint
	Creates the attachments and constraints connecting two parts of the rig.
]=]
function Ragdoll._setupLimb(
	ragdoll,
	sourceLimb: BasePart,
	affectedLimb: BasePart,
	cframe0: CFrame,
	cframe1: CFrame,
	blueprint
)
	local noCollisionConstraint = Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone()
	noCollisionConstraint.Part0 = sourceLimb
	noCollisionConstraint.Part1 = affectedLimb
	table.insert(ragdoll._noCollisionConstraints, noCollisionConstraint)
	noCollisionConstraint.Parent = ragdoll._noCollisionConstraintFolder

	local attachment0 = ragdoll._trove:Add(Instance.new("Attachment"))
	attachment0.CFrame = cframe0
	attachment0.Parent = sourceLimb

	local attachment1 = ragdoll._trove:Add(Instance.new("Attachment"))
	attachment1.CFrame = cframe1
	attachment1.Parent = affectedLimb

	local socket = Ragdoll.BALLSOCKETCONSTRAINT_TEMPLATE:Clone()
	socket.Name = affectedLimb.Name
	socket.Attachment0 = attachment0
	socket.Attachment1 = attachment1
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	table.insert(ragdoll._sockets, socket)
	socket.Parent = ragdoll._socketFolder

	local socketSettings = blueprint.socketSettings[affectedLimb.Name]
	if socketSettings ~= nil then
		for key, value in socketSettings do
			if socket[key] then
				socket[key] = value
			end
		end
	end
end

--[=[
	@private
	@param ragdoll Ragdoll
	@param blueprint Blueprint
	Loops through all motor6Ds and attaches their Part1s to the ragdoll.
	:::caution

	 This function should only be called once. If you use the RagdollFactory it is already called for you.

	:::
]=]
function Ragdoll._setupLimbs(ragdoll, blueprint)
	for _, motor6D: Motor6D in ragdoll._motor6Ds do
		local sourceLimb = motor6D.Part0
		local affectedLimb = motor6D.Part1
		local override = blueprint.cframeOverrides[affectedLimb.Name]
		local cframe0 = if override then override.C0 else motor6D.C0
		local cframe1 = if override then override.C1 else motor6D.C1
		Ragdoll._setupLimb(ragdoll, sourceLimb, affectedLimb, cframe0, cframe1, blueprint)
	end
end

--@ignore
function Ragdoll._activateRagdollPhysics(ragdoll, accessoryHandles, motor6Ds, limbs, noCollisionConstraints, sockets)
	if ragdoll._ragdolled then
		return
	end

	ragdoll._ragdolled = true
	ragdoll.Humanoid.WalkSpeed = 0
	ragdoll.Humanoid.AutoRotate = false
	ragdoll.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	ragdoll.HumanoidRootPart.CanCollide = false
	ragdoll.HumanoidRootPart.CustomPhysicalProperties = ROOT_PART_PHYSICAL_PROPERTIES

	for _, handle in accessoryHandles do
		handle.CanCollide = false
		handle.CanTouch = false
		handle.Massless = true
	end

	for _, motor6D: Motor6D in motor6Ds do
		motor6D.Enabled = false
	end

	for _, limb in limbs do
		limb.CanCollide = true
		limb.CustomPhysicalProperties = LIMB_PHYSICAL_PROPERTIES
	end

	for _, constraint: Constraint in noCollisionConstraints do
		constraint.Enabled = true
	end

	for _, socket: Constraint in sockets do
		socket.Enabled = true
	end

	ragdoll.RagdollBegan:Fire()
end

--[=[
	Activates ragdoll physics.
]=]
function Ragdoll:activateRagdollPhysics()
	Ragdoll._activateRagdollPhysics(
		self,
		self._accessoryHandles,
		self._motor6Ds,
		self._limbs,
		self._noCollisionConstraints,
		self._sockets
	)
end

--[=[
	Activates ragdoll physics in low detail mode.
]=]
function Ragdoll:activateRagdollPhysicsLowDetail()
	Ragdoll._activateRagdollPhysics(
		self,
		self._accessoryHandles,
		self._lowDetailMotor6Ds,
		self._limbs,
		self._noCollisionConstraints,
		self._lowDetailModeSockets
	)
end

--[=[
	Deactivates ragdoll physics.
]=]
function Ragdoll:deactivateRagdollPhysics()
	if not self._ragdolled then
		return
	end

	self._ragdolled = false
	self.Humanoid.WalkSpeed = self._originalSettings[self.Humanoid].WalkSpeed
	self.Humanoid.AutoRotate = self._originalSettings[self.Humanoid].AutoRotate
	self.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	self.HumanoidRootPart.CanCollide = self._originalSettings[self.HumanoidRootPart].CanCollide
	self.HumanoidRootPart.CustomPhysicalProperties =
		self._originalSettings[self.HumanoidRootPart].CustomPhysicalProperties

	for _, handle in self._accessoryHandles do
		handle.CanCollide = self._originalSettings[handle].CanCollide
		handle.CanTouch = self._originalSettings[handle].CanTouch
		handle.Massless = self._originalSettings[handle].Massless
	end

	for _, motor6D: Motor6D in self._motor6Ds do
		motor6D.Enabled = self._originalSettings[motor6D].Enabled
	end

	for _, limb in self._limbs do
		limb.CanCollide = self._originalSettings[limb].CanCollide
		limb.CustomPhysicalProperties = self._originalSettings[limb].CustomPhysicalProperties
	end

	for _, constraint: Constraint in self._noCollisionConstraints do
		constraint.Enabled = false
	end

	for _, socket: Constraint in self._sockets do
		socket.Enabled = false
	end

	self.RagdollEnded:Fire()
end

--[=[
	Activates ragdoll physics, then deactivates it when the ragdoll has remained still for 1.5 seconds.
]=]
function Ragdoll:collapse()
	if self._collapsed then
		return
	end

	self._collapsed = true
	self:activateRagdollPhysics()
	self.Collapsed:Fire()

	-- local timer = 0
	-- local lastPos = self.HumanoidRootPart.Position

	-- local connection
	-- connection = self._trove:Connect(RunService.Heartbeat, function(dt)
	-- 	if not self._ragdolled then
	-- 		self._collapsed = false
	-- 		self._trove:Remove(connection)
	-- 		return
	-- 	end

	-- 	timer += dt
	-- 	if timer < RAGDOLL_TIMEOUT_INTERVAL then
	-- 		return
	-- 	end

	-- 	local newPos = self.HumanoidRootPart.Position
	-- 	local distance = (newPos - lastPos).Magnitude
	-- 	lastPos = newPos
	-- 	timer -= RAGDOLL_TIMEOUT_INTERVAL
	-- 	if distance >= RAGDOLL_TIMEOUT_DISTANCE_THRESHOLD then
	-- 		return
	-- 	end

	-- 	self._collapsed = false
	-- 	self._trove:Remove(connection)
	-- 	if self.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
	-- 		self:freeze()
	-- 	else
	-- 		self:deactivateRagdollPhysics()
	-- 	end
	-- end)
end

--[=[
	Activates ragdoll physics in low detail mode, then deactivates it when the ragdoll has remained still for 1.5 seconds.
]=]
function Ragdoll:collapseLowDetail()
	if self._collapsed then
		return
	end

	self._collapsed = true
	self:activateRagdollPhysicsLowDetail()
	self.Collapsed:Fire()
end

--[=[
	Anchors all of the ragdoll's BaseParts.
]=]
function Ragdoll:freeze()
	if self._frozen then
		return
	end
	self._frozen = true
	self.HumanoidRootPart.Anchored = true

	for _, part in self._limbs do
		part.Anchored = true
	end
end

--[=[
	Returns all of the ragdoll's BaseParts to their original settings.
]=]
function Ragdoll:unfreeze()
	if not self._frozen then
		return
	end
	self._frozen = false
	self.HumanoidRootPart.Anchored = self._originalSettings[self.HumanoidRootPart].Anchored

	for _, part in self._limbs do
		part.Anchored = self._originalSettings[part].Anchored
	end
end

--[=[
	Returns true if ragdoll physics is active on this ragdoll.
]=]
function Ragdoll:isRagdolled(): boolean
	return self._ragdolled
end

--[=[
	Returns true if the ragdoll has callapsed.
]=]
function Ragdoll:isCollapsed(): boolean
	return self._collapsed
end

--[=[
	Returns true if the ragdoll is frozen.
]=]
function Ragdoll:isFrozen(): boolean
	return self._frozen
end

--[=[
	Destroys the ragdoll.
]=]
function Ragdoll:destroy()
	self.Destroying:Fire()
	self._trove:Destroy()
end

--[=[
	@within Ragdoll
	@method Destroy
	Alias for destroy().
]=]
Ragdoll.Destroy = Ragdoll.destroy

export type Ragdoll = {
	Character: Model,
	Humanoid: Humanoid,
	HumanoidRootPart: BasePart,
	RagdollBegan: Signal.Signal<()>,
	RagdollEnded: Signal.Signal<()>,
	Collapsed: Signal.Signal<()>,
	Destroying: Signal.Signal<()>,
	isRagdolled: (self: Ragdoll) -> boolean,
	isCollapsed: (self: Ragdoll) -> boolean,
	isFrozen: (self: Ragdoll) -> boolean,
	activateRagdollPhysics: (self: Ragdoll) -> (),
	activateRagdollPhysicsLowDetail: (self: Ragdoll) -> (),
	deactivateRagdollPhysics: (self: Ragdoll) -> (),
	collapse: (self: Ragdoll) -> (),
	collapseLowDetail: (self: Ragdoll) -> (),
	freeze: (self: Ragdoll) -> (),
	unfreeze: (self: Ragdoll) -> (),
	destroy: (self: Ragdoll) -> (),
	Destroy: (self: Ragdoll) -> (),
}

return Ragdoll
