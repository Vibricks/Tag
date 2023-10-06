local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameInfo = ReplicatedStorage.GameInfo

local Knit = require(ReplicatedStorage.Packages.Knit)

local InputService = Knit.GetService("InputService")
local StateManagerService = Knit.GetService("StateManagerService")


local module = {}

function module.ChangeServerMessage(Msg, Color)
    local DefaultColor = Color3.fromRGB(255, 255, 255)
    GameInfo.ServerMessage:SetAttribute("Color", Color or DefaultColor)
    GameInfo.ServerMessage.Value = Msg
end

function module:ReturnToLobby(Character)
    task.defer(function()
        local plr = game.Players:GetPlayerFromCharacter(Character)
        if not plr then return end
        InputService.Client.CancelClimbing:Fire(plr)
        StateManagerService:UpdateState(Character, "Ragdolled", 0)
        task.wait(.25)
        Character:PivotTo(workspace.Lobby.SpawnLocation.CFrame * CFrame.new(0, 3, 0))
    end)
end


return module