local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ReplicaService = require(ReplicatedStorage.Packages.ReplicaService)

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
	Name = "ReplicaController",
})

local EXPECTED_PROFILE_LISTENERS = {
	--"PlayerProfile",
}

local registeredListeners = {}

function module:Register(replicaClassName, callback)
	ReplicaService.ReplicaOfClassCreated(replicaClassName, callback)
	table.insert(registeredListeners, replicaClassName)
end

function module:KnitStart()
	task.defer(function()
		while #registeredListeners < #EXPECTED_PROFILE_LISTENERS do
			task.wait()
		end
		ReplicaService.RequestData()
	end)
end

function module:KnitInit()

end

return module