local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local SpinUI = Player:WaitForChild("PlayerGui"):WaitForChild("SpinUI")

local ShopFrame = LobbyUI:WaitForChild("Shop")

local Shared = require(script.Parent.Shared)
local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)

local SFX = game:GetService("SoundService").SFX
local module = {}
local Connections = {}
local CurrentTab = ShopFrame.Container.WeaponsTab

local frameModuleCache = {}

for i, v in pairs(script:GetChildren()) do
    if v:IsA("ModuleScript") then
        frameModuleCache[v.Name] = require(v)
    end
end


for i, v in pairs(ShopFrame.Container.Buttons:GetChildren()) do
    local Button = v:FindFirstChild("Button")
    local Tab = ShopFrame.Container:FindFirstChild(v.Name.."Tab")
    if Button then
        Button.MouseButton1Click:Connect(function()
            SFX.Click:Play()
            if Tab then
                if CurrentTab == Tab then return end
                CurrentTab.Visible = false
                CurrentTab = Tab
                Tab.Visible = true
            else
                local ComingSoon = ShopFrame.Container.ComingSoon
                CurrentTab.Visible = false
                CurrentTab = ComingSoon
                ComingSoon.Visible = true
            end
        end)
    end
end


function module:Toggle(Bool)
    local Close = function()
        Shared.CurrentFrame = nil
        ShopFrame.Visible = false
        game.Lighting.UI_BLUR.Enabled = false
    end

    if Bool == true then
        ShopFrame.Visible = true
        Shared.CurrentFrame = ShopFrame

        --* Connecting to the close button
        if not Connections["Close"] then
            local closeButton = ShopFrame.Container.Buttons.Close
            Connections ["Close"] = closeButton.Button.MouseButton1Click:Connect(function()
                SFX.Click:Play()
                Close()
            end)
        end
    else
        Close()
    end
end



return module