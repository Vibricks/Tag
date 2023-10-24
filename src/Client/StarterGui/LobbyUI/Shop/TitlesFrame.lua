local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local SpinUI = Player:WaitForChild("PlayerGui"):WaitForChild("SpinUI")

local ShopFrame = LobbyUI:WaitForChild("Shop")
local TitlesTab = ShopFrame.Container.TitlesTab

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
    TitlesTab.Middle.Restock.TextLabel.Text = ReplicatedStorage.GameInfo.RestockMessage.Value
end))

--! loading all items in the current stock 
local Grid = TitlesTab.Middle.Grid

local function LoadStock(Stock)
    for i, v in pairs(Grid:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "SampleFrame" then 
            v:Destroy()
        end
    end

    for rarity, rarityStock in pairs(Stock) do
        for _, TitleName in pairs(rarityStock) do        
            local Title = ReplicatedStorage.Assets.Titles:FindFirstChild(TitleName, true)
            local Display = Shared:createTitleDisplay(Title, Title.Parent.Name, "Rarity")
            if PlayerProfileReplica.Data.Inventory.Titles[TitleName] then
                Display.Owned.Visible = true
            end
            Display.Parent = Grid
        end
    end
end
local x, Stock = ShopService:GetCurrentStock("Titles"):await()

LoadStock(Stock)

ShopService.StocksChanged:Connect(function(Stocks, firstInit)
    if firstInit or not Stocks.Titles then return end
    LoadStock(Stocks.Titles)
end)


--* Loading the rates
local function LoadRates()
    for i, v in pairs(SpinUI.RarityChart:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "Sample" then
            v:Destroy()
        end
    end
    
    for rarity, percent in pairs(ShopData.TitleSpin.Rates) do
        local rarityText = SpinUI.RarityChart.Sample:Clone()
        rarityText.Parent = SpinUI.RarityChart
        rarityText.Text = tostring(rarity)..": "..tostring(percent).."%"
        rarityText.TextColor3 = ShopData.RarityColors[rarity]
        rarityText.Visible = true
        rarityText.LayoutOrder = -percent
    end
end

--*Spinning
TitlesTab.Buttons.SpinButton.Button.MouseButton1Click:Connect(function()
    SFX.Click:Play()
    ShopService:Spin("Titles"):andThen(function(SelectedTitle, SpinTime)
        --* Clear existing items inside the slider
        for _, child in pairs(SpinUI.SpinFrame.Slider:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "SampleFrame" then
                child:Destroy()
            end
        end

        SpinUI.Enabled = true
        ShopFrame.Visible = false
        Grid[SelectedTitle.Name].Owned.Visible = true
        local _, Stock = ShopService:GetCurrentStock("Titles"):await()

        ShopData.TitleSpin.CurrentStock = Stock

        Shared:Spin(SelectedTitle, ShopData.TitleSpin, SpinTime)
    end)
end)


return module