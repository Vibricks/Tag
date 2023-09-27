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
local vaultConnection

local module = {}

--check if part is above when tryin to vault or move
local function partCheck(ledge)
	local vaultPartCheck = workspace:Raycast(ledge.Position + Vector3.new(0, -1, 0) + ledge.LookVector * 1, ledge.UpVector * 3, raycastParams)
	if vaultPartCheck == nil then
		return true
	else
		return false
	end
end

--detect ledges
function module.detectLedge()
	if canVault and (Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Humanoid:GetState() == Enum.HumanoidStateType.Jumping) then
		local vaultCheck = workspace:Raycast(HRP.CFrame.Position, HRP.CFrame.LookVector * 5, raycastParams)
		if vaultCheck then
			if vaultCheck.Instance then		

				--Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				local localPos = vaultCheck.Instance.CFrame:PointToObjectSpace(vaultCheck.Position)
				local localLedgePos = Vector3.new(localPos.X, vaultCheck.Instance.Size.Y/2, localPos.Z)
				local ledgePos = vaultCheck.Instance.CFrame:PointToWorldSpace(localLedgePos)
				local ledgeOffset = CFrame.lookAt(ledgePos, ledgePos - vaultCheck.Normal)

				local magnitude = (ledgePos - Head.Position).Magnitude
				if magnitude < 4 then
					if partCheck(ledgeOffset) then
						canVault = false
						
						--screen shake
						-- camShake:Start()
						-- local dashShake = camShake:ShakeOnce(.36, 12, 0, .5)
						-- dashShake:StartFadeOut(.5)
						
						--player follows this part(you dont exactly need it but it makes tweening the player when they move easier unless there is a better way to do this but idk)
						ledgePart = Instance.new("Part")
						ledgePart.Parent = workspace
						ledgePart.Anchored = true
						ledgePart.Size = Vector3.one
						ledgePart.CFrame = ledgeOffset + Vector3.new(0, -2, 0) + ledgeOffset.LookVector * -1
						ledgePart.CanQuery = false
						ledgePart.CanCollide = false
						ledgePart.CanTouch = false
						ledgePart.Transparency = 1
						
						--play anim and sound
						--grabAnim:Play()
						--playSound()
						InputService:ToggleLedgeGrab(true)
						AnimationController:PlayAnimation("LedgeGrab")
						
						--connection while player is on a ledge
						vaultConnection = RunService.RenderStepped:Connect(function(dt)
							HRP.Anchored = true
							Humanoid.AutoRotate = false -- so shift lock doesnt't rotate character
							HRP.CFrame = HRP.CFrame:Lerp(CFrame.lookAt(ledgePart.Position, (ledgePart.CFrame * CFrame.new(0, 0, -1)).Position), .25)
							Humanoid:ChangeState(Enum.HumanoidStateType.Seated)
						end)
					end
				end
			end
		end
	elseif not canVault then
		canVault = true
		InputService:ToggleLedgeGrab(false)
		AnimationController:StopAnimation("LedgeGrab")

		Humanoid.AutoRotate = true
		HRP.Anchored = false
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		--grabAnim:Stop()
		
		--check if it exists and then disconnect
		if vaultConnection then
			vaultConnection:Disconnect()
		end

		if ledgePart then
			ledgePart:Destroy()
		end
	end
end

--pc and console support
UserInputService.InputBegan:Connect(function(input, gp)
	if (input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.Space) then
		module.detectLedge()
	end
end)

--mobile support
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled and not UserInputService.GamepadEnabled and not GuiService:IsTenFootInterface() then
	local jumpButton = Player.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
	jumpButton.Activated:Connect(function()
		module.detectLedge()
	end)
end

return module