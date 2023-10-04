local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Head = Character:WaitForChild("Head")
local Hum = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local Animator = Hum:WaitForChild("Animator")
local Camera = workspace.CurrentCamera

local Promise = require(ReplicatedStorage.Packages.Promise)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Util = require(ReplicatedStorage.Shared.Util)
local StateReader = require(ReplicatedStorage.Shared.StateReader)

local CanVault = true
local CA = Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.Movement.Vaulting)
CA:AdjustSpeed(2)
local module = {}

local InputService
Knit.OnStart():andThen(function()
	InputService = Knit.GetService("InputService")
end)


local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {Character}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function IsVaultable(Wall)
	local model = Wall:FindFirstAncestorOfClass("Model")
	if (model and model.Name == "Vault") or Wall.Name == "Vault" then
		return true
	end
	return false
end
local function FindNearbyVault()
	--warn("loop")
	if StateReader:IsStateEnabled(Character, "Sprinting") and Hum.MoveDirection.Magnitude > 0.01 then
		--warn("we sprint")
		--local NearestParts = workspace:GetPartBoundsInRadius(HRP.Position, 10)
		--for i, v in pairs(NearestParts) do
			--print(i,v)
			--if v.Name == "Vault" then
				local Dir = HRP.CFrame.LookVector * 7 --+ HRP.CFrame.UpVector * -5
				local wallhitResults = workspace:Raycast(HRP.CFrame.Position, Dir, raycastParams)
				if wallhitResults and wallhitResults.Instance then
					local Wall = wallhitResults.Instance
					if Wall.Anchored == true and Wall.CanCollide == true and IsVaultable(Wall) and CanVault then
						if Hum.FloorMaterial ~= Enum.Material.Air then
							InputService:Vault()
							CanVault = false
							local Vel = Instance.new("BodyVelocity")
							Vel.Parent = HRP
							Vel.Velocity = Vector3.new(0,0,0)
							Vel.MaxForce = Vector3.new(1,1,1) * math.huge
							Vel.Velocity = HRP.CFrame.LookVector * 20 + Vector3.new(0,math.abs(Wall.Position.Y-HRP.Position.Y)+10,0)
							CA:Play()
							game.Debris:AddItem(Vel, .3)
							task.wait(0.75)
							CA:Stop()
							task.wait(.25)
							CanVault = true
						end
					end
				end
			--end
		--end
	end
end

RunService.RenderStepped:Connect(FindNearbyVault)

return module