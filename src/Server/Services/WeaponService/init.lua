local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local WeaponService = Knit.CreateService {
    Name = "WeaponService",
    Client = {},
}

local PlayerDataService

function WeaponService:EquipWeapon(Player)
    local plrData = PlayerDataService:GetProfile(Player).Replica.Data
    local CurrentWeapon = plrData.Inventory.CurrentWeapon
    if CurrentWeapon ~= "None" then
        warn("Equipping", CurrentWeapon)
    else
        warn("There's no weapon to equip")
    end
end

function WeaponService.Client:UpdateCurrentWeapon(Player, Type, weaponName)
    local Replica = PlayerDataService:GetProfile(Player).Replica
    local plrData = Replica.Data
    if Type == "Equip" and plrData.Inventory.TagWeapons[weaponName] then
        if plrData.Inventory.TagWeapons[weaponName].Amount >= 1 then
            Replica:SetValue({"Inventory", "CurrentWeapon"}, weaponName)
            return true
        end
    elseif Type == "Unequip" then
        Replica:SetValue({"Inventory", "CurrentWeapon"}, "None")
        return true
    end
    return false
end


function WeaponService:KnitStart()

end


function WeaponService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
end


return WeaponService
