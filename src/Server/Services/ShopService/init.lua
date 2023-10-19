local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)
local Util = require(ReplicatedStorage.Shared.Util)
local SyncedTime = require(ServerScriptService.Modules.SyncedTime)
SyncedTime.init() -- Will make the request to google.com if it hasn't already.

local Weapons = ReplicatedStorage.Assets.Weapons


local ShopService = Knit.CreateService {
    Name = "ShopService",
    Client = {
        StockChanged = Knit.CreateSignal(),
    },
}

local PlayerDataService


local function toHMS(s)
    return string.format("%02i:%02i:%02i", s/60^2, s/60%60, s%60)
end

function ShopService:GetNewWeaponStock(Seed)
    local newStock = {
        ["Common"] = {},
        ["Rare"] = {},
        ["Legendary"] = {},
    }
    local stockAmounts = {
        ["Common"] = 3,
        ["Rare"] = 2,
        ["Legendary"] = 1,
    }

    for rarity, Amount in pairs(stockAmounts) do
        local All = Weapons[rarity]:GetChildren()
        for i = 1, Amount do
            local rand = Random.new(Seed):NextInteger(1, #All)--math.random(1, #All)
            local Selected = All[rand].Name
            table.insert(newStock[rarity], Selected)
            table.remove(All, rand)
        end
    end
    warn("New Stock: \n", newStock)
    return newStock
end

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

function ShopService.Client:GetCurrentStock()
    return ShopData.WeaponSpin.CurrentStock
end

function ShopService:KnitStart()
    local currentDay -- initialize our CurrentDay variable.

    while true do
        local day = math.floor((SyncedTime.time()) / 60)-- * 60 * 24))
        local t = (math.floor(SyncedTime.time())) 
        local daypass = t % 60
        local timeleft = 60 - daypass
        local timeleftstring = toHMS(timeleft)
        
        local sentence = ("Restocks in: " .. timeleftstring)
        ReplicatedStorage.GameInfo.RestockMessage.Value = sentence
        if day ~= currentDay then
            local newStock = ShopService:GetNewWeaponStock(day)
            local firstInit = false
            if currentDay == nil then firstInit = true end
            currentDay = day
            ShopData.WeaponSpin.CurrentStock = newStock
            ShopService.Client.StockChanged:FireAll(newStock, firstInit)
        end
        task.wait(1)
    end
    
end

function ShopService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
end


return ShopService
