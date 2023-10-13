local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local QuestsFrame = LobbyUI:WaitForChild("Quests")

local Shared = require(script.Parent.Shared)
local module = {}
local Connections = {}

function module:Toggle(Bool)
    local function Close()
        QuestsFrame.Visible = false
        Shared.CurrentFrame = nil
        game.Lighting.UI_BLUR.Enabled = false
    end

    if Bool == true then
        QuestsFrame.Visible = true
        Shared.CurrentFrame = QuestsFrame
        --* Connecting to the close button
        if not Connections["Close"] then
            local closeButton = QuestsFrame.MainFrame.Close
            Connections ["Close"] = closeButton.Button.MouseButton1Click:Connect(function()
                Close()
            end)
        end
    else
        Close()
    end
end

return module