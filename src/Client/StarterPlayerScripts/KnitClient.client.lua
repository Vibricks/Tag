local Player = game.Players.LocalPlayer
local StarterPlayer = game:GetService("StarterPlayer")
local Controllers = StarterPlayer.StarterPlayerScripts.Controllers--:WaitForChild("Controllers")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

for _, v in pairs(Controllers:GetDescendants()) do
	if v:IsA("ModuleScript") and v.Name:match("Controller$") then
		require(v)
	end
end

Knit.Start():andThen(function()
	for i, v in pairs(StarterPlayer.StarterPlayerScripts.Components:GetChildren()) do
		require(v)
	end
end)
	:catch(warn)
