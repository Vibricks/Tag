local CollectionService = game:GetService("CollectionService")
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
	TAGGER_SPEED_BOOST = 8,
}

local StateProfileClassToken = ReplicaService.NewClassToken("StateProfile")


function module.CleanUpData(Index)
	local data = module.CharacterProfiles[Index]

	if module.CharacterProfiles[Index].Replica then
		data.Replica:Destroy()
	end

	for i, v in pairs(module.CharacterProfiles[Index].Connections) do
		v:Disconnect()
	end
	module.CharacterProfiles[Index] = nil
end

function module.Initialize(Character)
	local Player = game.Players:GetPlayerFromCharacter(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	local Index = Player or Character
	module.CharacterProfiles[Index] = {
		States = Util:DeepCopyTable(StatePresets);
		Connections = {};
		Replica =  {};
	}
	if Player then
		module.CharacterProfiles[Index].Replica = ReplicaService.NewReplica({
			ClassToken =  StateProfileClassToken;
			Tags = {Player = Player};
			Data = module.CharacterProfiles[Index].States;
			Replication = Player;
		})
	end
	
	--! Here is where we would update certain default states based on player data
	--~local _ = PlayerData and ProfileManager.CreateAbilityGauges (PlayerData, GaugesFolder)
	Humanoid.WalkSpeed = module.Defaults.WalkSpeed
	Humanoid.JumpPower = module.Defaults.JumpPower
	Humanoid.Died:Connect(function()
		if module.CharacterProfiles[Index] then
			module.CleanUpData(Index)
		end
	end)

	--! Make sure appearance is loaded before building ragdoll
	if Player then
		task.defer(function()
			if not Player:HasAppearanceLoaded() then
				Player.CharacterAppearanceLoaded:Wait()
			end
			if Player.Parent then
				RagdollManager.BuildRagdoll(Character)
			end
		end)
	end
end

function module:IsStateEnabled(Character, StateName)
	local Player = game.Players:GetPlayerFromCharacter(Character)
	local StateEnabled 
	if Player then
		StateEnabled = StateReader:IsStateEnabled(Character, StateName)
	end
	return StateEnabled
end



function module:UpdateState(Character, StateName, NewValue)
	local Player = game.Players:GetPlayerFromCharacter(Character)
	local State = self:RetrieveState(Character, StateName)
	if State then
		if Player then
			local replica = module.CharacterProfiles[Player].Replica 

			local StateType = State.StateType
			if StateType == "Timed" then
				replica:SetValue({StateName, "StartTime"}, tick())
				replica:SetValue({StateName, "Duration"}, NewValue)

				State.Duration = NewValue
			elseif StateType == "Bool" then
				replica:SetValue({StateName, "Bool"}, NewValue)
			end
		else
			--? POTENTIAL NPC LOGIC GOES HERE
		end
	else
		warn("State not found")
	end
end


function module:RetrieveState(Character: Model, StateName: string)
	local Player = game.Players:GetPlayerFromCharacter(Character) 
	local State
	if Player then
		State = StateReader:RetrieveState(Player, StateName)
	else
		--? POTENTIAL NPC LOGIC GOES HERE
	end
	return State
end

function module:SetCooldown(Character, CooldownName, Duration)
	local Player = game.Players:GetPlayerFromCharacter(Character) 
	if Player then
		local replica = module.CharacterProfiles[Player].Replica
		if not replica.Data.Cooldowns[CooldownName] then
			replica:SetValue({"Cooldowns", CooldownName}, {})
		end
		replica:SetValues({"Cooldowns", CooldownName}, {
			Duration = Duration,
		})
		--! IMPORTANT, we set the start time AFTER because it serves as a listner for the client to get the updated values
		replica:SetValue({"Cooldowns", CooldownName, "StartTime"}, workspace:GetAttribute("ElaspedTime"))
	else
		--? POTENTIAL NPC LOGIC GOES HERE
	end
end

function  module:IsOnCooldown(Character, CooldownName)
	local Player = game.Players:GetPlayerFromCharacter(Character) 
	if Player then
		local replica = module.CharacterProfiles[Player].Replica
		local Cooldown = replica.Data.Cooldowns[CooldownName]
		if Cooldown then
			if workspace:GetAttribute("ElaspedTime") - Cooldown.StartTime <= Cooldown.Duration then
				return true
			end
		end
		return false
	else
		--? POTENTIAL NPC LOGIC GOES HERE
	end
end

function module:GetCharacterDefaultSpeed(Character)
	local IsTagger = CollectionService:HasTag(Character, "Taggers")
	local DefaultSpeed =  module.Defaults.WalkSpeed
	local TotalSpeed = DefaultSpeed
	if IsTagger then 
		TotalSpeed += module.Defaults.TAGGER_SPEED_BOOST
	end
	return TotalSpeed
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

end

function module:KnitInit()
	
end

return module