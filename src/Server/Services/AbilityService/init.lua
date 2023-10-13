local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)


local AbilityService = Knit.CreateService {
    Name = "AbilityService",
    Client = {},
}

local PlayerDataService


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

function AbilityService:KnitStart()
    
end


function AbilityService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
end


return AbilityService
