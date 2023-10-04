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

function module:RetrieveState(Character, StateName)
	local Replica
	--* Grabbing the replica based on server or client
	if RunService:IsServer() then
		if StateManagerService.CharacterProfiles[Character] then --* If the characters state profile exsits
			Replica = StateManagerService.CharacterProfiles[Character].Replica --* Grab the replica
		end
	else
		Replica = ReplicaInterfaceController:GetReplica("StateProfile")
	end
	--* Returning the state
	if Replica.Data[StateName] then
		return Replica.Data[StateName]
	else
		warn("STATE: ", StateName, " -NOT FOUND")
	end
end

function module:IsStateEnabled(Character, StateName)
    local State = self:RetrieveState(Character, StateName)

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

return module