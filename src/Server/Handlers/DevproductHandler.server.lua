local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.OnStart():await()
local PlayerDataService = Knit.GetService("PlayerDataService")



local MarketplaceService = game:GetService("MarketplaceService")

function getPlayerFromId(id)
	for i,v in pairs(game.Players:GetChildren()) do
		if v.userId == id then
			return v
		end
	end
	return nil
end
 
local CashProductIDs = {
    ["1669984546"] = 1000,
    ["1669989592"] = 2500,
    ["1669990393"] = 5000,
    ["1669990946"] = 10000,
}
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local productId = receiptInfo.ProductId
	local playerId = receiptInfo.PlayerId
	local player = getPlayerFromId(playerId)
	local productName 
	local ProfileReplica = PlayerDataService:GetProfile(player).Replica

    if CashProductIDs[tostring(productId)] then
        local newAmount = ProfileReplica.Data.Coins + CashProductIDs[tostring(productId)]
        ProfileReplica:SetValue({"Coins"}, newAmount)
    end

	return Enum.ProductPurchaseDecision.PurchaseGranted		
end
