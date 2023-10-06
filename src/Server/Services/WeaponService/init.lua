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

function WeaponService:KnitStart()

end


function WeaponService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
end


return WeaponService
