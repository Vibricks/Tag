--! Warning: only use this to read PLAYER states, for NPCS directly use the statemanager
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local StateManagerService
local ReplicaInterfaceController
Knit.OnStart():andThen(function()
	if RunService:IsServer() then
		StateManagerService = Knit.GetService("StateManagerService")
	elseif RunService:IsClient() then
		ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
	end
end)
local module = {}

function module:_GetReplica(Player: Player)
	local Replica
	--* Grabbing the replica based on server or client
	if RunService:IsServer() then
		if StateManagerService.CharacterProfiles[Player] then --* If the characters state profile exsits
			Replica = StateManagerService.CharacterProfiles[Player].Replica --* Grab the replica
		else
		end
	else
		Replica = ReplicaInterfaceController:GetReplica("StateProfile")
	end
	return Replica
end

function module:RetrieveState(Player: Player, StateName: string)
	local Replica = self:_GetReplica(Player)
	--* Returning the state
	if Replica.Data[StateName] then
		return Replica.Data[StateName]
	else
		warn("STATE: ", StateName, " -NOT FOUND")
	end
end

function module:IsStateEnabled(Character: Model, StateName: string)
	local Hum = Character:FindFirstChild("Humanoid")
	if not Character or not Hum or Hum.Health <= 0 then return end
	local Player = game.Players:GetPlayerFromCharacter(Character)
    local State = self:RetrieveState(Player, StateName)

	if State then
		local StateType = State.StateType
		local ToReturn
		if StateType == "Timed" then
		
			if workspace:GetAttribute("ElaspedTime") - State.StartTime >= State.Duration  then
				ToReturn = false
			else
				ToReturn = true
			end	
		elseif StateType == "Bool" then
			ToReturn = State.Bool
		end
		return ToReturn
	end
end

function  module:IsOnCooldown(Character: Model, CooldownName: string)
	local Player = game.Players:GetPlayerFromCharacter(Character)
	local Replica = self:_GetReplica(Player)
	local Cooldown = Replica.Data.Cooldowns[CooldownName]
	
	if Cooldown then
		if workspace:GetAttribute("ElaspedTime") - Cooldown.StartTime <= Cooldown.Duration then
			return true
		end
	end
	return false
end


return module