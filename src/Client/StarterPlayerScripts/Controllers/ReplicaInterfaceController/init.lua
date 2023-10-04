local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ReplicaController = require(ReplicatedStorage.Packages.ReplicaService)

--[[
	ReplicaService docs:
	"All .NewReplicaSignal and .ReplicaOfClassCreated() listeners should be connected
	before calling .RequestData()! - refrain from connecting listeners afterwards!"
	
	Previously I was calling RequestData in PlayerDataController:KnitInit *before*
	connecting ReplicaOfClassCreated listeners, which caused race conditions.
	
	This module will connect all ReplicaOfClassCreated listeners before calling
	RequestData.
--]]

local module = Knit.CreateController({
	Name = "ReplicaInterfaceController",
})

module.ReplicaCache = {}

local EXPECTED_REPLICAS = {
	"PlayerProfile",
	"StateProfile"
}

function module:GetReplica(replicaName)
	local replica = module.ReplicaCache[replicaName]
	if table.find(EXPECTED_REPLICAS, replicaName) and not replica then 
		repeat
			task.wait(.1)
		until module.ReplicaCache[replicaName] ~= nil
		replica = module.ReplicaCache[replicaName]
	end
	if replica then
		return replica
	else
		warn("REPLICA", replicaName, "NOT FOUND")
	end
end


function module:KnitStart()
	for i = 1, #EXPECTED_REPLICAS do
		local replicaClassName = EXPECTED_REPLICAS[i]
		ReplicaController.ReplicaOfClassCreated(replicaClassName, function(replica)
			if replica.Tags.Player == Knit.Player then
				module.ReplicaCache[replicaClassName] = replica
			end
		end)
	end
	ReplicaController.RequestData()
end

function module:KnitInit()

end

return module