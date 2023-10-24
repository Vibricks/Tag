local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameInfo = ReplicatedStorage.GameInfo

local Knit = require(ReplicatedStorage.Packages.Knit)

local RoundService = Knit.GetService("RoundService")
local InputService = Knit.GetService("InputService")
local StateManagerService = Knit.GetService("StateManagerService")


local module = {}

function module.ChangeServerMessage(Msg, Color)
    local DefaultColor = Color3.fromRGB(255, 255, 255)
    GameInfo.ServerMessage:SetAttribute("Color", Color or DefaultColor)
    GameInfo.ServerMessage.Value = Msg
end

function module:ReturnToLobby(Character)
    local function RemoveGamemodeAssets()
        local Head = Character:FindFirstChild("Head")

        local TeamOverhead = Head and Head:FindFirstChild("TeamOverhead")
        local Highlight = Character:FindFirstChild("TeamColorHighlight")

        if TeamOverhead then TeamOverhead:Destroy() end
        if Highlight then Highlight:Destroy() end
    end

    task.defer(function()
        local plr = game.Players:GetPlayerFromCharacter(Character)
        if not plr then return end
        InputService.Client.CancelClimbing:Fire(plr)
        RoundService.Client.ReflectOnUI:Fire(plr, "ReturnToLobby")
        StateManagerService:UpdateState(Character, "Ragdolled", 0)
        StateManagerService:UpdateState(Character, "Sprinting", false)
        local Humanoid = Character:FindFirstChild("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = StateManagerService.Defaults.WalkSpeed
        end

        RemoveGamemodeAssets()
        task.wait(.25)
        Character:PivotTo(workspace.Lobby.SpawnLocation.CFrame * CFrame.new(0, 3, 0))
    end)
end


return module