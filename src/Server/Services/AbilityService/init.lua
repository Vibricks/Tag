local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Util = require(ReplicatedStorage.Shared.Util)
local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)


local AbilityService = Knit.CreateService {
    Name = "AbilityService",
    Client = {},
}

local PlayerDataService
local StateManagerService

local AbilityCache = {}




function AbilityService.Client:EquipAbility(Player, AbilityName)
    local Profile = PlayerDataService:GetProfile(Player)
    if Profile.Replica.Data.Inventory.Abilities[AbilityName] then
        Profile.Replica:SetValue({"Inventory", "CurrentAbility"}, AbilityName)
        return "Equipped"
    end
end

function AbilityService.Client:UnequipAbility(Player, AbilityName)
    local Profile = PlayerDataService:GetProfile(Player)
    if Profile.Replica.Data.Inventory.CurrentAbility == AbilityName then
        Profile.Replica:SetValue({"Inventory", "CurrentAbility"}, "None")
        return "Unequipped"
    end
end

function AbilityService.Client:UseAbility(Player)
    local Character = Player.Character
	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")
    if not Character or not Humanoid then return end
    local Profile = PlayerDataService:GetProfile(Player)
    local Ability = Profile.Replica.Data.Inventory.CurrentAbility

    local Profile = PlayerDataService:GetProfile(Player)
    local IsSliding = StateManagerService:IsStateEnabled(Character, "Sliding")
    local IsAttacking = StateManagerService:IsStateEnabled(Character, "Attacking")
    local LedgeGrabbing = StateManagerService:IsStateEnabled(Character, "LedgeGrabbing")
    local IsClimbing = StateManagerService:IsStateEnabled(Character, "Climbing")
    local IsTagger = CollectionService:HasTag(Character, "Taggers")
    local GameInProgress = ReplicatedStorage.GameInfo.GameInProgress.Value
    if not IsClimbing and not IsSliding and not IsAttacking and not LedgeGrabbing and not StateManagerService:IsOnCooldown(Character, "Ability") 
    and Profile.Replica.Data.Inventory.CurrentAbility ~= "None" then
        if AbilityCache[Ability] then
            StateManagerService:SetCooldown(Character, "Ability", ShopData.Abilities[Ability].Cooldown)

            AbilityCache[Ability](Player)
        end
    end
end



function AbilityService:KnitStart()
    
end


function AbilityService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
    StateManagerService = Knit.GetService("StateManagerService")

    for i, v in pairs(script:GetChildren()) do
        if v:IsA("ModuleScript") then
            AbilityCache[v.Name] = require(v)
        end
    end
end


return AbilityService
