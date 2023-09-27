local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ReplicationService = Knit.CreateService {
    Name = "ReplicationService",
    Client = {},
}


function ReplicationService:KnitStart()
    
end


function ReplicationService:KnitInit()
    
end


return ReplicationService
