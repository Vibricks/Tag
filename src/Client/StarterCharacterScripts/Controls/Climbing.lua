local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Character = Player.Character or Player.CharacterAdded:Wait()
local Head = Character:WaitForChild("Head")
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local Animator = Humanoid:WaitForChild("Animator")
local Camera = workspace.CurrentCamera

local Promise = require(ReplicatedStorage.Packages.Promise)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Util = require(ReplicatedStorage.Shared.Util)

local StateReader = require(ReplicatedStorage.Shared.StateReader)

local InputService
local AnimationController 
local ClimbingBar = PlayerGui:WaitForChild("RoundUI"):WaitForChild("ClimbingBar")
Knit.OnStart():andThen(function()
	InputService = Knit.GetService("InputService")
	AnimationController = Knit.GetController("AnimationController")
end)

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {Character}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local ledgePart
local climbPart
local vaultConnection
local climbConnection

local currentlyGrabbingLedge
local currentlyClimbing

local module = {}

function createIgnorePart(CFrame)
	local ignorePart = Instance.new("Part")
	ignorePart.Parent = workspace.Ignore
	ignorePart.Anchored = true
	ignorePart.Size = Vector3.one
	ignorePart.CFrame = CFrame
	ignorePart.CanQuery = false
	ignorePart.CanCollide = false
	ignorePart.CanTouch = false
	ignorePart.Transparency = 1
	return ignorePart
end

--check if part is above when tryin to vault or move

local function GetUp()
	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.Parent = Character:WaitForChild("Head")
	BodyVelocity.P = 9e9
	BodyVelocity.MaxForce = Vector3.one * math.huge
	BodyVelocity.Velocity = Vector3.new(0,40,0) + HRP.CFrame.LookVector * 5
	game.Debris:AddItem(BodyVelocity,.15)
end

local function isLedge(wallhitResults)
	if not wallhitResults then return end
	local ledge = wallhitResults.Instance
	local localPos = ledge.CFrame:PointToObjectSpace(wallhitResults.Position)
	local localLedgePos = Vector3.new(localPos.X, wallhitResults.Instance.Size.Y/2, localPos.Z)
	local ledgePos = ledge.CFrame:PointToWorldSpace(localLedgePos)
	local ledgeOffset = CFrame.lookAt(ledgePos, ledgePos - wallhitResults.Normal)

	local magnitude = (ledgePos - Head.Position).Magnitude
	if magnitude < 4 then
		local wallaboveLedge = workspace:Raycast(ledgeOffset.Position + Vector3.new(0, -1, 0) + ledgeOffset.LookVector * 1, ledgeOffset.UpVector * 3, raycastParams)
		if wallaboveLedge == nil then
			return true, ledgeOffset
		end
	end
	return false
end

function module.EndLedgeGrab()
	--local IsLedgeGrabbing = StateReader:IsStateEnabled(Character, "LedgeGrabbing")
	if currentlyGrabbingLedge then
		currentlyGrabbingLedge = false
		InputService:ToggleLedgeGrab(false)

		Humanoid.AutoRotate = true
		HRP.Anchored = false
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		--grabAnim:Stop()
		
		--check if it exists and then disconnect
		if vaultConnection then vaultConnection:Disconnect() end

		if ledgePart then ledgePart:Destroy() end
		GetUp()
		task.delay(0.15, function()
			AnimationController:StopAnimation("LedgeGrab")
		end)
	
	end
end

local function toggleLedgeGrab(bool, ledgeOffset)
	if bool == true then
		currentlyGrabbingLedge = true
							
		--player follows this part(you dont exactly need it but it makes tweening the player when they move easier unless there is a better way to do this but idk)
		ledgePart = createIgnorePart(ledgeOffset + Vector3.new(0, -2, 0) + ledgeOffset.LookVector * -1)

		InputService:ToggleLedgeGrab(true)
		local anim = AnimationController:PlayAnimation("LedgeGrab")
		anim:AdjustWeight(10)
		
		--connection while player is on a ledge
		vaultConnection = RunService.RenderStepped:Connect(function(dt)
			HRP.Anchored = true
			Humanoid.AutoRotate = false -- so shift lock doesnt't rotate character
			HRP.CFrame = HRP.CFrame:Lerp(CFrame.lookAt(ledgePart.Position, (ledgePart.CFrame * CFrame.new(0, 0, -1)).Position), .25)
			Humanoid:ChangeState(Enum.HumanoidStateType.Seated)
		end)

		task.delay(0.1, module.EndLedgeGrab)
	--else
	--	module.EndLedgeGrab()
	end
end

local tweenConnection
local BodyVelocity
local BodyGyro
local climbAnim
local ClimbDebounce = false

function module.EndClimb(Result)
	if currentlyClimbing then
		currentlyClimbing = false
		Humanoid.AutoRotate = true

		if climbConnection then climbConnection:Disconnect() end
		if climbAnim and climbAnim.IsPlaying then climbAnim:Stop() end
		if BodyVelocity then BodyVelocity.Velocity = Vector3.zero BodyVelocity:Destroy() end
		if BodyGyro then BodyGyro:Destroy() end

		InputService:ToggleClimb(false)

		if Result == "ClimbTimeOver" then
			ClimbingBar.Debounce.Visible = true
			task.wait(.5)
			if not currentlyClimbing then
				ClimbingBar.Visible = false
				ClimbingBar.Debounce.Visible = false
			end
		else
			--ClimbDebounce = false

			ClimbingBar.Visible = false
		end
	end
end


local function toggleClimb(bool, wallhitResults)
	local IsClimbing = StateReader:IsStateEnabled(Character, "Climbing")
	local IsLedgeGrabbing = StateReader:IsStateEnabled(Character, "LedgeGrabbing")
	if bool == true and not  IsClimbing and not IsLedgeGrabbing and not ClimbDebounce then

		ClimbDebounce = true
		local Duration = 1
		ClimbingBar.Debounce.Visible = false
		ClimbingBar.Bar.Size = UDim2.fromScale(1,1)
		ClimbingBar.Visible = true

		ClimbingBar.Bar:TweenSize(UDim2.fromScale(0,1), "Out", "Quad", Duration, true)

		local ClimbingPromise = Promise.new(function(resolve, reject, onCancel)

			if HRP:FindFirstChildOfClass("BodyGyro") then HRP:FindFirstChildOfClass("BodyGyro") :Destroy() end
			if HRP:FindFirstChildOfClass("BodyVelocity") then HRP:FindFirstChildOfClass("BodyVelocity"):Destroy() end

			InputService:ToggleClimb(true)
			currentlyClimbing = true
			local Speed = 30

			BodyGyro = Instance.new("BodyGyro")
			BodyGyro.Name = "ClimbGyro"
			BodyGyro.P = 9e9
			BodyGyro.D = 1
			BodyGyro.MaxTorque = Vector3.one * math.huge
			BodyGyro.Parent = HRP
			BodyGyro.CFrame = CFrame.new(HRP.Position, HRP.Position + (-wallhitResults.Normal))
			game.Debris:AddItem(BodyGyro, Duration)
	
			BodyVelocity = Instance.new("BodyVelocity")
			BodyVelocity.Name = "ClimbVelocity"
			BodyVelocity.MaxForce = Vector3.one * math.huge
			BodyVelocity.P = 1e9
			BodyVelocity.Velocity = Vector3.zero
			BodyVelocity.Parent = HRP
			game.Debris:AddItem(BodyVelocity, Duration)
			climbAnim = AnimationController:PlayAnimation("Scaling", {Looped = true, Priority = Enum.AnimationPriority.Action2})
			--climbAnim:Play()
			climbAnim:AdjustSpeed(1.75)

			local StartPoint = CFrame.new(wallhitResults.Position + Vector3.new(0, 0, -5))-- + ledgeOffset.LookVector * -1

			climbConnection = RunService.RenderStepped:Connect(function(deltaTime)
				Humanoid.AutoRotate = false
	
				BodyVelocity.Velocity = StartPoint.UpVector * Speed
				local wallNormal = -wallhitResults.Normal
				BodyGyro.CFrame = CFrame.new(HRP.Position, HRP.Position + wallNormal)
	
				--local p = (HRP.CFrame * CFrame.new(0,2,2)).Position
				local wallhitResults = Promise.new(function(resolve)
					--for i = 1, 1 do
						local origin = (HRP.CFrame * CFrame.new(0,0,-.5)).Position
						local dir =  HRP.CFrame.LookVector * 10
						local results = workspace:Raycast(origin ,dir, raycastParams)

						if results and results.Instance then
							local foundLedge, ledgeOffset = isLedge(wallhitResults)
							if foundLedge and not currentlyGrabbingLedge then
								resolve("LedgeFound", {ledgeOffset = ledgeOffset})
								--break
							 end
						else
							resolve("NoMoreWall")
							--if i == 3 then resolve("NoMoreWall") end
						end
					--end
				end)

				local roofhitResults = Promise.new(function(resolve)
					for i = 1, 3 do
						local origin = (HRP.CFrame * CFrame.new((1+(-1*i))+1,2,0)).Position
						local results = workspace:Raycast(origin, HRP.CFrame.UpVector * 2, raycastParams)
						if results and results.Instance then
							resolve("RoofHit")
						end
					end
				end)

				return Promise.race({roofhitResults, wallhitResults}):andThen(function(...)
					resolve(...)
				end)


			end)
		end)

		local ClimbDurationPromise = Promise.new(function(resolve)
			task.wait(Duration)
			resolve("ClimbTimeOver")
		end)--:finally(function()

		--end)

		local Race = Promise.race({ClimbingPromise, ClimbDurationPromise})
		Race:andThen(function(Result, ExtraData)
			module.EndClimb(Result)
			if Result == "NoMoreWall" then
				local anim = AnimationController:PlayAnimation("LedgeGrab")
				GetUp()
				task.delay(.2, function()
					anim:Stop()
				end)
			elseif Result == "ClimbTimeOver" then

			elseif Result == "LedgeFound" then
				local ledgeOffset = ExtraData.ledgeOffset
				toggleLedgeGrab(true, ledgeOffset)
			end
		end)
	else
		module.EndClimb()
	end
end

--detect ledges
function module.detectWall(mobile)
	if (Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Humanoid:GetState() == Enum.HumanoidStateType.Jumping) or mobile then
		local wallhitResults = workspace:Raycast(HRP.CFrame.Position, HRP.CFrame.LookVector * 5, raycastParams)
		if wallhitResults then
			if wallhitResults.Instance and wallhitResults.Instance.Anchored == true and wallhitResults.Instance.CanCollide == true then		

				local foundLedge, ledgeOffset = isLedge(wallhitResults)
				if foundLedge and not currentlyGrabbingLedge then
					toggleLedgeGrab(true, ledgeOffset)
				else
					toggleClimb(true, wallhitResults)
				end
			end
		end
	elseif currentlyGrabbingLedge then
		toggleLedgeGrab(false)
	elseif currentlyClimbing then
		toggleClimb(false)
	end
end

local lastPress = tick()
--pc and console support
UserInputService.InputBegan:Connect(function(input, gp)
	if (input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.Space) then
		module.detectWall()
	end
end)

Humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.Landed then
		ClimbDebounce = false
	end
end)
--mobile support
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled and not UserInputService.GamepadEnabled and not GuiService:IsTenFootInterface() then
	local jumpButton = Player.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
	jumpButton.Activated:Connect(function()
		module.detectWall(true)
	end)
end

local UserGameSettings = UserSettings():GetService("UserGameSettings")
UserGameSettings.RotationType = Enum.RotationType.CameraRelative

Humanoid.AutoJumpEnabled = false
return module