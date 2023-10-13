local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local RoundUI = Player:WaitForChild("PlayerGui"):WaitForChild("RoundUI")
local InventoryFrame = LobbyUI:WaitForChild("Inventory")

local SFX = game:GetService("SoundService").SFX

local Knit = require(ReplicatedStorage.Packages.Knit)
local Shared = require(script.Parent.Shared)
local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)


local ShopService = Knit.GetService("ShopService")
local AbilityService = Knit.GetService("AbilityService")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")


local module = {}
local Connections = {}
local ClickDebounce = false
local CurrentTab = InventoryFrame.AbilityTab
local frameModuleCache = {}

for i, v in pairs(script:GetChildren()) do
    if v:IsA("ModuleScript") then
        frameModuleCache[v.Name] = require(v)
        frameModuleCache[v.Name]:Setup()
    end
end

for i, v in pairs(InventoryFrame.Buttons:GetChildren()) do
    local Button = v:FindFirstChild("Button")
    local Tab = InventoryFrame:FindFirstChild(v.Name.."Tab")
    if Button and Tab then
        Button.MouseButton1Click:Connect(function()
            SFX.Click:Play()
            if CurrentTab == Tab then return end
            CurrentTab.Visible = false
            CurrentTab = Tab
            Tab.Visible = true
        end)
    end
end


function module:Toggle(Bool)
    local function Close()
        InventoryFrame.Visible = false
        Shared.CurrentFrame = nil
        game.Lighting.UI_BLUR.Enabled = false
    end
    if Bool == true then
        InventoryFrame.Visible = true
        Shared.CurrentFrame = InventoryFrame
        --* Connecting to the close button
        
        if not Connections["Close"] then
            local closeButton = InventoryFrame.Buttons.Close
            Connections["Close"] = closeButton.Button.MouseButton1Click:Connect(function()
                Close()
            end)
        end

    else
        Close()
    end
end




return module