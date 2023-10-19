local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local SpinUI = Player:WaitForChild("PlayerGui"):WaitForChild("SpinUI")

local ShopFrame = LobbyUI:WaitForChild("Shop")
local WeaponsTab = ShopFrame.Container.WeaponsTab

local SFX = game:GetService("SoundService").SFX

local Knit = require(ReplicatedStorage.Packages.Knit)
local Shared = require(script.Parent.Parent.Shared)
local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)

local ShopService = Knit.GetService("ShopService")
local AbilityService = Knit.GetService("AbilityService")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")

local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")


local module = {}

Shared.ConnectionTrove:Add(ReplicatedStorage.GameInfo.RestockMessage:GetPropertyChangedSignal("Value"):Connect(function()
    WeaponsTab.Middle.Restock.TextLabel.Text = ReplicatedStorage.GameInfo.RestockMessage.Value
end))

--! loading all items in the current stock 
local Grid = WeaponsTab.Middle.Grid

local function LoadStock(Stock)
    for i, v in pairs(Grid:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "SampleFrame" then 
            v:Destroy()
        end
    end
    -- print(table.foreach(ReplicatedStorage.Assets.Weapons:GetDescendants(), function(i,v)
    --     if v:IsA("Model") then
    --         return v.Name
    --     end
    -- end))

    for rarity, rarityStock in pairs(Stock) do
        for _, WeaponName in pairs(rarityStock) do
            local Weapon = ReplicatedStorage.Assets.Weapons:FindFirstChild(WeaponName, true)
            local Display = Shared:createWeaponDisplay(Weapon, Weapon.Parent.Name, "Rarity")
            if PlayerProfileReplica.Data.Inventory.TagWeapons[WeaponName] then
                Display.Owned.Visible = true
            end
            Display.Parent = Grid
        end
    end
end
local x, Stock = ShopService:GetCurrentStock():await()
print(x, Stock)

LoadStock(Stock)

ShopService.StockChanged:Connect(function(Stock, firstInit)
    if firstInit then return end
    LoadStock(Stock)
end)

--* Loading the rates
for i, v in pairs(SpinUI.RarityChart:GetChildren()) do
    if v:IsA("Frame") and v.Name ~= "Sample" then
        v:Destroy()
    end
end

for rarity, percent in pairs(ShopData.WeaponSpin.Rates) do
    local rarityText = SpinUI.RarityChart.Sample:Clone()
    rarityText.Parent = SpinUI.RarityChart
    rarityText.Text = tostring(rarity)..": "..tostring(percent).."%"
    rarityText.TextColor3 = ShopData.RarityColors[rarity]
    rarityText.Visible = true
    rarityText.LayoutOrder = -percent
end
--*Spinning
WeaponsTab.Buttons.SpinButton.Button.MouseButton1Click:Connect(function()
    SFX.Click:Play()
    ShopService:WeaponSpin():andThen(function(SelectedWeapon, SpinTime)
        --* Clear existing items inside the slider
        for _, child in pairs(SpinUI.SpinFrame.Slider:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "SampleFrame" then
                child:Destroy()
            end
        end

        SpinUI.Enabled = true
        ShopFrame.Visible = false
        Grid[SelectedWeapon.Name].Owned.Visible = true
        local _, Stock = ShopService:GetCurrentStock():await()

        ShopData.WeaponSpin.CurrentStock = Stock

        Shared:Spin(SelectedWeapon, ShopData.WeaponSpin, SpinTime)
    end)
end)


return module