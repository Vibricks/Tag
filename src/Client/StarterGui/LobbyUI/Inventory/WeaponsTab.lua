local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local RoundUI = Player:WaitForChild("PlayerGui"):WaitForChild("RoundUI")
local InventoryFrame 

local WeaponsTab 
local Grid 
local InfoFrame


local SFX = game:GetService("SoundService").SFX

local Knit = require(ReplicatedStorage.Packages.Knit)
local Shared = require(script.Parent.Parent.Shared)
local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)

local ShopService = Knit.GetService("ShopService")
local WeaponService = Knit.GetService("WeaponService")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")

local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")

local Weapons = ReplicatedStorage.Assets:WaitForChild("Weapons")


local module = {}

local CurrentSelectedWeapon

function module:Setup()
    LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
    InventoryFrame = LobbyUI:WaitForChild("Inventory")
    WeaponsTab = InventoryFrame.WeaponsTab
    InfoFrame = WeaponsTab.InfoFrame
    Grid = WeaponsTab.MainFrame.ScrollingFrame

    UpdateWeaponsOwned()
    local TagWeapons = PlayerProfileReplica.Data.Inventory.TagWeapons

    for i, v in pairs(TagWeapons) do
        AddNewWeapon(i)
    end
    
    Shared.ConnectionTrove:Add(InfoFrame.Equip.Button.MouseButton1Click:Connect(function()
        SFX.Click:Play()
        local Type = InfoFrame.Equip:GetAttribute("Type")
        WeaponService:UpdateCurrentWeapon(Type, CurrentSelectedWeapon):andThen(function(Result)
            if Result == true then
                local newType = Type == "Equip" and "Unequip" or "Equip"
                ChangeEquipButton(newType)
            else
                SFX.Error:Play()
            end
        end)
    end))

    Shared.ConnectionTrove:Add(PlayerProfileReplica:ListenToNewKey({"Inventory", "TagWeapons"}, function(newIndex, newValue)
        AddNewWeapon(newValue)
    end))

    local Equip = LobbyUI.Inventory.WeaponsTab.InfoFrame.Equip
    Equip:SetAttribute("Type", "Equip")
end



function UpdateWeaponsOwned()
    local TotalWeapons = 0
    local OwnedWeapons = 0

    for i, v in pairs(ReplicatedStorage.Assets.Weapons:GetDescendants()) do
        if v.Parent:IsA("Folder") and not v:IsA("Folder") then
            TotalWeapons += 1
        end
    end

    for i, v in pairs(PlayerProfileReplica.Data.Inventory.TagWeapons) do
        OwnedWeapons += 1
    end
    WeaponsTab.MainFrame.AmountOwned.Text = OwnedWeapons.."/"..TotalWeapons.." Owned"
end

function ChangeEquipButton(Type)
    if Type == "Equip" then
        InfoFrame.Equip.TextLabel.Text = "Equip"
        InfoFrame.Equip.BackgroundColor3 = Color3.fromRGB(121, 255, 72)
        InfoFrame.Equip:SetAttribute("Type", "Equip")

    elseif Type == "Unequip" then
        InfoFrame.Equip.TextLabel.Text = "Unequip"
        InfoFrame.Equip.BackgroundColor3 = Color3.fromRGB(255, 72, 78)
        InfoFrame.Equip:SetAttribute("Type", "Unequip")
    end
end


function AddNewWeapon(weaponName)
    local originalWeaponObject: Instance = Weapons:FindFirstChild(weaponName, true)
    local rarity = originalWeaponObject.Parent.Name

    local weaponDisplay = Shared:createWeaponDisplay(originalWeaponObject, rarity, "Rarity")
    weaponDisplay.Parent = Grid
    
    Shared.ConnectionTrove:Add(weaponDisplay.Button.MouseButton1Click:Connect(function()
        SFX.Click:Play()
        Shared:setViewport(InfoFrame.WeaponDisplay.ItemViewport, originalWeaponObject)
        InfoFrame.Title.Text = weaponName
        InfoFrame.Title.TextColor3 = ShopData.RarityColors[rarity]
        InfoFrame.WeaponDisplay.BackgroundColor3 = ShopData.RarityColors[rarity]
        InfoFrame.Rarity.Text = rarity
        InfoFrame.Rarity.TextColor3 = ShopData.RarityColors[rarity]
        CurrentSelectedWeapon = weaponName
        if PlayerProfileReplica.Data.Inventory.CurrentWeapon ~= weaponName then
            ChangeEquipButton("Equip")
        else
            ChangeEquipButton("Unequip")
        end
    end))
end


return module