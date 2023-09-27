local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)

for _, v in pairs(ServerScriptService.Services:GetChildren()) do
	if v:IsA("ModuleScript") and v.Name:match("Service$") then
		require(v)
	end
end

Knit.Start():andThen(function()
	for i, v in pairs(ServerScriptService.Components:GetChildren()) do
		require(v)
	end
end)
	:catch(warn)
