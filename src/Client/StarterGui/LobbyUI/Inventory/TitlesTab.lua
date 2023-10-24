local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local RoundUI = Player:WaitForChild("PlayerGui"):WaitForChild("RoundUI")
local InventoryFrame 

local TitlesTab 
local Grid 
local InfoFrame


local SFX = game:GetService("SoundService").SFX

local Knit = require(ReplicatedStorage.Packages.Knit)
local Shared = require(script.Parent.Parent.Shared)
local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)

local ShopService = Knit.GetService("ShopService")
local CosmeticService = Knit.GetService("CosmeticService")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")

local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")

local Titles = ReplicatedStorage.Assets:WaitForChild("Titles")


local module = {}

local CurrentSelectedTitle
function module:Setup()
    LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
    InventoryFrame = LobbyUI:WaitForChild("Inventory")
    TitlesTab = InventoryFrame.TitlesTab
    InfoFrame = TitlesTab.InfoFrame
    Grid = TitlesTab.MainFrame.ScrollingFrame

    UpdateTitlesOwned()
    local OwnedTitles = PlayerProfileReplica.Data.Inventory.Titles

    for i, v in pairs(OwnedTitles) do
        AddnewTitle(i)
    end
    
    Shared.ConnectionTrove:Add(InfoFrame.Equip.Button.MouseButton1Click:Connect(function()
        SFX.Click:Play()
        local Type = InfoFrame.Equip:GetAttribute("Type")
        CosmeticService:UpdateCurrentTitle(Type, CurrentSelectedTitle):andThen(function(Result)
            if Result == true then
                local newType = Type == "Equip" and "Unequip" or "Equip"
                ChangeEquipButton(newType)
            else
                SFX.Error:Play()
            end
        end)
    end))

    Shared.ConnectionTrove:Add(PlayerProfileReplica:ListenToNewKey({"Inventory", "Titles"}, function(newIndex, newValue)
        AddnewTitle(newValue)
    end))

    local Equip = LobbyUI.Inventory.TitlesTab.InfoFrame.Equip
    Equip:SetAttribute("Type", "Equip")
end



function UpdateTitlesOwned()
    local TotalTitles = 0
    local OwnedTitles = 0

    for i, v in pairs(ReplicatedStorage.Assets.Titles:GetDescendants()) do
        if v.Parent:IsA("Folder") and not v:IsA("Folder") then
            TotalTitles += 1
        end
    end

    for i, v in pairs(PlayerProfileReplica.Data.Inventory.Titles) do
        OwnedTitles += 1
    end
    TitlesTab.MainFrame.AmountOwned.Text = OwnedTitles.."/"..TotalTitles.." Owned"
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


function AddnewTitle(titleName)
    local TitleHolder: Instance = Titles:FindFirstChild(titleName, true)
    local rarity = TitleHolder.Parent.Name

    local titleDisplay = Shared:createTitleDisplay(TitleHolder, rarity, "Rarity")
    titleDisplay.Parent = Grid
    titleDisplay.Visible = true
    
    Shared.ConnectionTrove:Add(titleDisplay.Button.MouseButton1Click:Connect(function()
        SFX.Click:Play()
        InfoFrame.PlrThumbnail.ImageLabel.Image =_G.PlrThumbnail
        InfoFrame.Title.Text = titleName
        InfoFrame.Title.TextColor3 = TitleHolder.Title.TextLabel.TextColor3
        InfoFrame.PlrThumbnail.ImageLabel.Visible = true
        local foundGradient = InfoFrame.Title:FindFirstChild("UIGradient")
        if foundGradient then
            foundGradient:Destroy()
        end

        
        local particles = TitleHolder:FindFirstChildOfClass("ParticleEmitter") 
        if particles then
            InfoFrame.PlrThumbnail.AuraIcon.Visible = true
            InfoFrame.PlrThumbnail.AuraIcon.Image = particles.Texture
        end

        if TitleHolder.Title.TextLabel:FindFirstChild("UIGradient") then
            TitleHolder.Title.TextLabel.UIGradient:Clone().Parent = InfoFrame.Title
        end

        InfoFrame.PlrThumbnail.BackgroundColor3 = ShopData.RarityColors[rarity]
        InfoFrame.Rarity.Text = rarity
        InfoFrame.Rarity.TextColor3 = ShopData.RarityColors[rarity]
        CurrentSelectedTitle = titleName
        if PlayerProfileReplica.Data.Inventory.CurrentTitle ~= titleName then
            ChangeEquipButton("Equip")
        else
            ChangeEquipButton("Unequip")
        end
    end))
end


return module