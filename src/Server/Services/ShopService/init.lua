local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)

local Weapons = ReplicatedStorage.Assets.Weapons

local ShopService = Knit.CreateService {
    Name = "ShopService",
    Client = {},
}

local PlayerDataService


function ShopService.Client:PurchaseAbility(Player, AbilityName)
    local Profile = PlayerDataService:GetProfile(Player)

    if ShopData.Abilities[AbilityName] and not Profile.Replica.Data.Inventory.Abilities[AbilityName] then
        Profile.Replica:SetValue({"Inventory", "Abilities", AbilityName}, {})
        Profile.Replica:SetValues({"Inventory", "Abilities", AbilityName}, {
            Upgrades = 1
        })
        return "Purchased"
    end
end

function ShopService.Client:WeaponSpin(Player)
    local Profile = PlayerDataService:GetProfile(Player)

    local Rates = ShopData.WeaponSpin.Rates
    local plrChance = Random.new():NextNumber() * 100
    local Weight = 0
    local rarityChosen

    for rarity, percentage in pairs(Rates) do
        Weight += percentage
        if plrChance <= Weight then
            rarityChosen = rarity
            break
        end
    end

    --* Getting the weapons we can potentially obtain from this spin
    local unboxableWeapons = {}
    for _, weapons in pairs(ShopData.WeaponSpin.CurrentStock) do
        for i = 1, #weapons do
            table.insert(unboxableWeapons, weapons[i])
        end
    end

    --* Shuffling the weapons 
    for i = #unboxableWeapons, 2, -1 do
        local j = Random.new():NextInteger(1, i)
        unboxableWeapons[i], unboxableWeapons[j] = unboxableWeapons[j], unboxableWeapons[i]
    end

    local SelectedWeapon = nil
			
    for _, itemName in pairs(unboxableWeapons) do
        if Weapons:FindFirstChild(itemName, true).Parent.Name == rarityChosen then
            SelectedWeapon = Weapons:FindFirstChild(itemName, true)
            break
        end
    end

    if not Profile.Replica.Data.Inventory.TagWeapons[SelectedWeapon.Name] then
        Profile.Replica:SetValue({"Inventory", "TagWeapons", SelectedWeapon.Name}, {Amount = 1})
    end
    Profile.Replica:SetValues({"Inventory", "TagWeapons",  SelectedWeapon.Name}, {
        Amount = Profile.Replica.Data.Inventory.TagWeapons[SelectedWeapon.Name].Amount + 1 
    })
    return SelectedWeapon, Random.new():NextNumber(3, 7)
end

function ShopService:KnitStart()
    
end


function ShopService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
end


return ShopService
