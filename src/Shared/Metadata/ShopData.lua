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
        Common = {"Green Brick", "Yellow Brick", "Orange Brick"};
        Rare = {"Blue Brick", "White Brick"};
        Legendary = {"Red Brick"}
    };
    Storage = ReplicatedStorage.Assets:WaitForChild("Weapons")
}

ShopData.Abilities = {
    ["Invisibility"] = {
        Price = 500, 
        Description = "Allows the user to go invisible for a few seconds",
        Icon = "rbxassetid://14961717058",
        UpgradePrices = {5,10,15}
    }

}


return ShopData