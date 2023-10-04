local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameInfo = ReplicatedStorage.GameInfo

local module = {}

function module.ChangeServerMessage(Msg, Color)
    local DefaultColor = Color3.fromRGB(255, 255, 255)
    GameInfo.ServerMessage:SetAttribute("Color", Color or DefaultColor)
    GameInfo.ServerMessage.Value = Msg
end



return module