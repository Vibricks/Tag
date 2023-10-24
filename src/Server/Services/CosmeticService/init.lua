local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Titles = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Titles")

local CosmeticService = Knit.CreateService {
    Name = "CosmeticService",
    Client = {},
}

local PlayerDataService


function  CosmeticService:ApplyTitle(Character)
    local Player = game.Players:GetPlayerFromCharacter(Character)
    local Data = PlayerDataService:GetProfile(Player).Replica.Data

    local CurrentTitle = Data.Inventory.CurrentTitle
    local TitleHolder = Titles:FindFirstChild(CurrentTitle, true) 
    if not Character then return end

    if Character.Head:FindFirstChild("Title") then
        Character.Head.Title:Destroy()
    end

    if Character.Head:FindFirstChild("TitleParticle") then
        Character.Head.TitleParticle:Destroy()
    end

    if CurrentTitle ~= "None" and TitleHolder then
        local Title = TitleHolder.Title:Clone()
        local _, Size = Character:GetBoundingBox()
        local Offset = Vector3.new(0,(Size.Y/2)-.5,0)

        Title.StudsOffset = Offset
        Title.Parent = Character.Head

        local foundParticle = TitleHolder:FindFirstChildOfClass("ParticleEmitter")
        if foundParticle then
            local TitleParticle = foundParticle:Clone()
            TitleParticle.Name = "TitleParticle"
            TitleParticle.Parent = Character.Head
        end
    end
end


function CosmeticService.Client:UpdateCurrentTitle(Player, Type, titleName)
    local Replica = PlayerDataService:GetProfile(Player).Replica
    local plrData = Replica.Data
    if Type == "Equip" and plrData.Inventory.Titles[titleName] then
        if plrData.Inventory.Titles[titleName].Amount >= 1 then
            Replica:SetValue({"Inventory", "CurrentTitle"}, titleName)
            CosmeticService:ApplyTitle(Player.Character)
            return true
        end
    elseif Type == "Unequip" then
        Replica:SetValue({"Inventory", "CurrentTitle"}, "None")
        CosmeticService:ApplyTitle(Player.Character)
        return true
    end
    return false
end

function CosmeticService:KnitStart()
    
end


function CosmeticService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
end


return CosmeticService
