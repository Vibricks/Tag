local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)
local Util = require(ReplicatedStorage.Shared.Util)
local SyncedTime = require(ServerScriptService.Modules.SyncedTime)
SyncedTime.init() -- Will make the request to google.com if it hasn't already.

local Weapons = ReplicatedStorage.Assets.Weapons
local Titles = ReplicatedStorage.Assets.Titles


local ShopService = Knit.CreateService {
    Name = "ShopService",
    Client = {
        StocksChanged = Knit.CreateSignal(),
    },
}

local PlayerDataService

for i, v in pairs(Titles:GetDescendants()) do
    if v.Name == "IgnorePart" then
        v:Destroy()
    end
end


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

    ShopData.WeaponSpin.CurrentStock = newStock
    return newStock
end

function ShopService:GetNewTitleStock(Seed)
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
        local All = Titles[rarity]:GetChildren()
        for i = 1, Amount do
            local rand = Random.new(Seed):NextInteger(1, #All)--math.random(1, #All)
            local Selected = All[rand].Name
            table.insert(newStock[rarity], Selected)
            table.remove(All, rand)
        end
    end
    ShopData.TitleSpin.CurrentStock = newStock

    return newStock
end

function ShopService.Client:UpgradeAbility(Player, AbilityName)
    local Profile = PlayerDataService:GetProfile(Player)

    if ShopData.Abilities[AbilityName] and Profile.Replica.Data.Inventory.Abilities[AbilityName] then
        local CurrentUpgrades = Profile.Replica.Data.Inventory.Abilities[AbilityName].Upgrades
        if CurrentUpgrades < 3 then
            Profile.Replica:SetValues({"Inventory", "Abilities", AbilityName}, {
                Upgrades = CurrentUpgrades + 1
            })
        else
            return ("Upgrades Maxed")
        end

        return "Upgraded"
    end
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

function ShopService.Client:Spin(Player, Type)
    local Profile = PlayerDataService:GetProfile(Player)

    local Rates = ShopData.WeaponSpin.Rates
    local plrChance = Random.new():NextNumber() * 100
    local Weight = 0
    local rarityChosen
    local InventorySlotName = "TagWeapons"
    local Storage = Weapons

    local CurrentStock = ShopData.WeaponSpin.CurrentStock

    if Type == "Titles" then
        Rates = ShopData.TitleSpin.Rates
        CurrentStock = ShopData.TitleSpin.CurrentStock
        InventorySlotName = "Titles"
        Storage = Titles
    end

    for rarity, percentage in pairs(Rates) do
        Weight += percentage
        if plrChance <= Weight then
            rarityChosen = rarity
            break
        end
    end

    --* Getting the item we can potentially obtain from this spin
    local unboxableItems = {}
    for _, items in pairs(CurrentStock) do
        for i = 1, #items do
            table.insert(unboxableItems, items[i])
        end
    end

    --* Shuffling the items 
    for i = #unboxableItems, 2, -1 do
        local j = Random.new():NextInteger(1, i)
        unboxableItems[i], unboxableItems[j] = unboxableItems[j], unboxableItems[i]
    end

    local SelectedItem = nil
			
    for _, itemName in pairs(unboxableItems) do
        if Storage:FindFirstChild(itemName, true).Parent.Name == rarityChosen then
            SelectedItem = Storage:FindFirstChild(itemName, true)
            break
        end
    end

    if not Profile.Replica.Data.Inventory[InventorySlotName][SelectedItem.Name] then
        Profile.Replica:SetValue({"Inventory", InventorySlotName, SelectedItem.Name}, {Amount = 1})
    end
    Profile.Replica:SetValues({"Inventory", InventorySlotName,  SelectedItem.Name}, {
        Amount = Profile.Replica.Data.Inventory[InventorySlotName][SelectedItem.Name].Amount + 1 
    })
    return SelectedItem, Random.new():NextNumber(3, 7)
end

function ShopService.Client:GetCurrentStock(Player, Type)
    local toReturn = ShopData.WeaponSpin.CurrentStock
    if Type == "Weapons" then
        toReturn = ShopData.WeaponSpin.CurrentStock
    elseif Type == "Titles" then
        toReturn =  ShopData.TitleSpin.CurrentStock
    end
    return toReturn
end

function ShopService:KnitStart()
    local currentDay -- initialize our CurrentDay variable.

    while true do
        local day = math.floor((SyncedTime.time()) / 60)--? * 60 * 24)) Add another *60 for 1 hour
        local t = (math.floor(SyncedTime.time())) 
        local daypass = t % 60
        local timeleft = 60 - daypass
        local timeleftstring = toHMS(timeleft)
        
        local sentence = ("Restocks in: " .. timeleftstring)
        ReplicatedStorage.GameInfo.RestockMessage.Value = sentence
        if day ~= currentDay then
            local Stocks = {
                ["Weapons"] =  ShopService:GetNewWeaponStock(day);
                ["Titles"] =  ShopService:GetNewTitleStock(day);
            }

            local firstInit = false
            if currentDay == nil then firstInit = true end
            currentDay = day

            ShopService.Client.StocksChanged:FireAll(Stocks, firstInit)
        end
        task.wait(1)
    end
    
end

function ShopService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
end


return ShopService
