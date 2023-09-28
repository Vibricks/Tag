local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local Player = game.Players.LocalPlayer
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

local InputService
local AnimationController 

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
	ignorePart.Parent = workspace
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

local function isLedge(wallhitResults)
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
	else
		currentlyGrabbingLedge = false
		InputService:ToggleLedgeGrab(false)
		AnimationController:StopAnimation("LedgeGrab")

		Humanoid.AutoRotate = true
		HRP.Anchored = false
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		--grabAnim:Stop()
		
		--check if it exists and then disconnect
		if vaultConnection then vaultConnection:Disconnect() end

		if ledgePart then ledgePart:Destroy() end
	end
end

local tweenConnection
local climbAnim = AnimationController:GetAnimation("Scaling", {Looped = true})

local function toggleClimb(bool, wallhitResults)
	
	local function endClimb()
		currentlyClimbing = false
		Humanoid.AutoRotate = true
		HRP.Anchored = false

		if climbConnection then climbConnection:Disconnect() end
		if tweenConnection then tweenConnection:Disconnect() end

		if climbPart then climbPart:Destroy() end
		if climbAnim and climbAnim.IsPlaying then climbAnim:Stop() end
		--AnimationController:StopAnimation("Scaling")
	end
	if bool == true then
		currentlyClimbing = true
		local startingPos = wallhitResults.Position 
		local Offset = CFrame.lookAt(startingPos, startingPos - wallhitResults.Normal) 
		

		climbPart = createIgnorePart(Offset + Offset.LookVector * -1.5)
		local tween = TweenService:Create(climbPart, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = climbPart.CFrame*CFrame.new(0,20,0)})
		tween:Play()
		climbAnim:Play()
		climbAnim:AdjustSpeed(1.5)

		climbConnection = RunService.RenderStepped:Connect(function(dt)
			HRP.Anchored = true
			Humanoid.AutoRotate = false -- so shift lock doesnt't rotate character
			HRP.CFrame = HRP.CFrame:Lerp(CFrame.lookAt(climbPart.Position, (climbPart.CFrame * CFrame.new(0, 0, -1)).Position), .25)
			Humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
			local wallhitResults = workspace:Raycast(HRP.CFrame.Position, HRP.CFrame.LookVector * 5, raycastParams)
			local foundLedge, ledgeOffset = isLedge(wallhitResults)

			if foundLedge and not currentlyGrabbingLedge then
				endClimb()
				toggleLedgeGrab(true, ledgeOffset)
			end

		end)
		tweenConnection = tween.Completed:Connect(function(playbackState)
			endClimb()
		end)
	else
		endClimb()
	end
end

--detect ledges
function module.detectWall()
	if (Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Humanoid:GetState() == Enum.HumanoidStateType.Jumping) then
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

--pc and console support
UserInputService.InputBegan:Connect(function(input, gp)
	if (input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.Space) then
		module.detectWall()
	end
end)

--mobile support
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled and not UserInputService.GamepadEnabled and not GuiService:IsTenFootInterface() then
	local jumpButton = Player.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
	jumpButton.Activated:Connect(function()
		module.detectWall()
	end)
end

return module