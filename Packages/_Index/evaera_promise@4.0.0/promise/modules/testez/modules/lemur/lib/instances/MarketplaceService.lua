local BaseInstance = import("./BaseInstance")
local InstanceProperty = import("../InstanceProperty")
local Signal = import("../Signal")
local MarketplaceService = BaseInstance:extend("MarketplaceService")

MarketplaceService.properties.PromptPurTaggerequested = InstanceProperty.readOnly({
	getDefault = function()
		return Signal.new()
	end,
})

MarketplaceService.properties.PromptProductPurTaggerequested = InstanceProperty.readOnly({
	getDefault = function()
		return Signal.new()
	end,
})

MarketplaceService.properties.PromptGamePassPurTaggerequested = InstanceProperty.readOnly({
	getDefault = function()
		return Signal.new()
	end,
})

MarketplaceService.properties.ServerPurchaseVerification = InstanceProperty.readOnly({
	getDefault = function()
		return Signal.new()
	end,
})

return MarketplaceService