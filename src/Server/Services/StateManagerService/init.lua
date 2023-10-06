local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Util = require(ReplicatedStorage.Shared.Util)
local ReplicaService = require(ReplicatedStorage.Packages.ReplicaService)
local StateReader = require(ReplicatedStorage.Shared.StateReader)
local StatePresets = require(script.StatePresets)
--local RagdollSystem = require(ReplicatedStorage.Packages.RagdollSystem)
local RagdollManager = require(ServerScriptService.Modules.RagdollManager)

local module = Knit.CreateService({
	Name = "StateManagerService",
	Client = {},
})



module.CharacterProfiles = {}
module.Defaults = {
	WalkSpeed = 22,
	JumpPower = 50,
	SPRINT_SPEED_INCREASE = 15,
}

local StateProfileClassToken = ReplicaService.NewClassToken("StateProfile")


local function CleanUpCharacterData(Character)
	print(Character.Name)
	local data = module.CharacterProfiles[Character]
	if data.Replica then
		data.Replica:Destroy()
	end
	for i, v in pairs(module.CharacterProfiles[Character].Connections) do
		v:Disconnect()
	end

	module.CharacterProfiles[Character] = nil
end

function module.Initialize(Character)
	local Player = game.Players:GetPlayerFromCharacter(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	module.CharacterProfiles[Character] = {
		States = Util:DeepCopyTable(StatePresets);
		Connections = {};
		Replica =  {};
	}
	if Player then
		module.CharacterProfiles[Character].Replica = ReplicaService.NewReplica({
			ClassToken =  StateProfileClassToken;
			Tags = {Player = Player};
			Data = module.CharacterProfiles[Character].States;
			Replication = Player;
		})
	end
	
	--//Here is where we would update certain default states based on player data
	--local _ = PlayerData and ProfileManager.CreateAbilityGauges (PlayerData, GaugesFolder)
	Humanoid.WalkSpeed = module.Defaults.WalkSpeed
	Humanoid.JumpPower = module.Defaults.JumpPower
	Humanoid.Died:Connect(function()
		if module.CharacterProfiles[Character] then
			CleanUpCharacterData(Character)
		end
	end)
	--// make sure appearance is loaded before building ragdoll
	task.defer(function()
		if not Player:HasAppearanceLoaded() then
			Player.CharacterAppearanceLoaded:Wait()
		end
		if Player.Parent then
			RagdollManager.BuildRagdoll(Character)
		end
	end)
end

function module:IsStateEnabled(Character, StateName)
	return StateReader:IsStateEnabled(Character, StateName)
end



function module:UpdateState(Character, StateName, NewValue)
	local State = self:RetrieveState(Character, StateName)
	local replica = module.CharacterProfiles[Character].Replica
	if State then
		local StateType = State.StateType
		if StateType == "Timed" then
			replica:SetValue({StateName, "StartTime"}, tick())
			replica:SetValue({StateName, "Duration"}, NewValue)

			State.Duration = NewValue
		elseif StateType == "Bool" then
			replica:SetValue({StateName, "Bool"}, NewValue)
		end
	else
		warn("State not found")
	end
end

function module:RetrieveState(Character, StateName)
	return StateReader:RetrieveState(Character, StateName)
end

function module:SetCooldown(Character, CooldownName, Duration)
	local replica = module.CharacterProfiles[Character].Replica
	if not replica.Data.Cooldowns[CooldownName] then
		replica:SetValue({"Cooldowns", CooldownName}, {})
	end
	replica:SetValues({"Cooldowns", CooldownName}, {
		Duration = Duration,
	})
	--!IMPORTANT, we set the start time AFTER because it serves as a listner for the client to get the updated values
	replica:SetValue({"Cooldowns", CooldownName, "StartTime"}, workspace:GetAttribute("ElaspedTime"))
end

function  module:IsOnCooldown(Character, CooldownName)
	local replica = module.CharacterProfiles[Character].Replica
	local Cooldown = replica.Data.Cooldowns[CooldownName]
	if Cooldown then
		if workspace:GetAttribute("TimeElapsed") - Cooldown.StartTime >= Cooldown.Duration then
			return true
		end
	end
	return false
end

function module:ChangeSpeed(Character,Speed,Duration, Priority, Disables)
	local Humanoid = Character:FindFirstChild("Humanoid")
	local DisableJump = Disables and Disables.DisableJump
	local DisableAutoRotate = Disables and Disables.DisableAutoRotate
	self:UpdateState(Character, "Speed", Duration)

	local SpeedData = self:RetrieveState(Character,"Speed")
	if not SpeedData then warn("No Speed Data") return end
	task.defer(function()
		if Priority >= SpeedData.Priority then
			SpeedData.Priority = Priority

			Humanoid.WalkSpeed = Speed
			Humanoid.JumpPower = DisableJump and 0 or Humanoid.JumpPower 
			Humanoid:SetAttribute("OldAutoRotate", Humanoid.AutoRotate)
			if DisableAutoRotate then
				Humanoid:SetAttribute("AutoRotateDisabledBySpeed", true)
				Humanoid.AutoRotate = false
			end

			while self:IsStateEnabled(Character, "Speed") do
				local SpeedData = self:RetrieveState(Character,"Speed")

				if SpeedData.Priority > Priority then
					break
				end
				RunService.Heartbeat:Wait()
			end		
			local IsSprinting = self:IsStateEnabled(Character, "Sprinting")
			local Speed = IsSprinting and module.Defaults.WalkSpeed + module.Defaults.SPRINT_SPEED_INCREASE or module.Defaults.WalkSpeed
			Humanoid.WalkSpeed = Speed
			Humanoid.JumpPower = module.Defaults.JumpPower
			SpeedData.Priority = 0
			if Humanoid:GetAttribute("AutoRotateDisabledBySpeed") then
				Humanoid.AutoRotate = true
				Humanoid:SetAttribute("AutoRotateDisabledBySpeed", nil)
			end
		else 
			warn("previous priority too high", SpeedData.Priority, Priority)
		end
	end)		
end

function module:KnitStart()
	for _, Player in pairs(game.Players:GetChildren()) do
		if Player and Player.Character then
			module.Initialize(Player.Character)
		end
	end
	
	game.Players.PlayerAdded:Connect(function(Player)
		Player.CharacterAdded:Connect(function(Character)
			module.Initialize(Character)
		end)
	end)

	game.Players.PlayerRemoving:Connect(function(player)
		CleanUpCharacterData(player.Character)
	end)
end

function module:KnitInit()
	
end

return module