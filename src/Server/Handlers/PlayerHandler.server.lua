local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.OnStart():await()

local StateManagerService = Knit.GetService("StateManagerService")


for _, Player in pairs(game.Players:GetChildren()) do
    if Player and Player.Character then
        StateManagerService.Initialize(Player.Character)
    end
    Player.CharacterAdded:Connect(function(Character)
        StateManagerService.Initialize(Character)
    end)
end

game:GetService("Players").PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(function(Character)
        StateManagerService.Initialize(Character)
    end)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    StateManagerService.CleanUpData(player)
end)