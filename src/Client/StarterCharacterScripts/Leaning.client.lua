local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local StateReader = require(ReplicatedStorage.Shared.StateReader)

local MOMENTUM_FACTOR = 0.008
local MIN_MOMENTUM = 0.285
local MAX_MOMENTUM = 0.285
local SPEED = 15

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local m6d = nil
local originalM6dC0 = nil

if humanoid.RigType == Enum.HumanoidRigType.R15 then
	local lowerTorso = character.LowerTorso
	m6d = lowerTorso.Root
else
	m6d = humanoidRootPart.RootJoint
end
originalM6dC0 = m6d.C0

runService.Heartbeat:Connect(function(dt)
	local IsClimbing = StateReader:IsStateEnabled(character, "Climbing")
	if IsClimbing then return end
	local direction = humanoidRootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
	local momentum = humanoidRootPart.CFrame:VectorToObjectSpace(humanoidRootPart.Velocity)*MOMENTUM_FACTOR
	momentum = Vector3.new(
		math.clamp(math.abs(momentum.X), MIN_MOMENTUM, MAX_MOMENTUM),
		0,
		math.clamp(math.abs(momentum.Z), MIN_MOMENTUM, MAX_MOMENTUM)
	)

	local x = direction.X*momentum.X
	local z = (direction.Z*momentum.Z) / 2

	local angles = nil
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		angles = {z, 0, -x}
	else
		angles = {-z, -x, 0}
	end

	m6d.C0 = m6d.C0:Lerp(originalM6dC0*CFrame.Angles(unpack(angles)), dt*SPEED)
end)