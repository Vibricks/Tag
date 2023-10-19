
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local SpinUI = Player:WaitForChild("PlayerGui"):WaitForChild("SpinUI")

local ShopFrame = LobbyUI:WaitForChild("Shop")
local CurrencyTab = ShopFrame.Container.CurrencyTab

local SFX = game:GetService("SoundService").SFX

local Knit = require(ReplicatedStorage.Packages.Knit)
local Shared = require(script.Parent.Parent.Shared)
local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)

local ShopService = Knit.GetService("ShopService")
local AbilityService = Knit.GetService("AbilityService")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")

local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")

local module = {}


for _, v in pairs(CurrencyTab.Grid:GetChildren()) do
    if v:IsA("Frame") then
        v.Purchase.Button.MouseButton1Click:Connect(function()
            SFX.Click:Play()
            local amount = v.Name
            if v:FindFirstChild("ID") then
                MarketplaceService:PromptProductPurchase(Player,tonumber(v.ID.Value))
            end
        end)
    end
end



return module