local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopData = {}

ShopData.RarityColors = {
    Common = Color3.fromRGB(66, 255, 126),
    Rare = Color3.fromRGB(20, 153, 255),
    Legendary = Color3.fromRGB(255, 177, 21)
}

ShopData.WeaponSpin = {
    Price = 200,
    Rates = {
        Common = 75;
        Rare = 20;
        Legendary = 5;
    },
    CurrentStock = {

    };
    Storage = ReplicatedStorage.Assets:WaitForChild("Weapons")
}

ShopData.Abilities = {
    ["Trap"] = {
        Price = 600, 
        Description = "Allows the user to go invisible for a few seconds",
        Icon = "rbxassetid://14961717058",
        UpgradePrices = {5,10,15},
        ExclusiveTo = "Taggers",
        Cooldown = 5
    }, 

    ["Invisibility"] = {
        Price = 1000, 
        Description = "Allows the user to go invisible for a few seconds",
        Icon = "rbxassetid://14961717058",
        UpgradePrices = {5,10,15},
        Cooldown = 20
    },



}


return ShopData