local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local RoundUI = Player:WaitForChild("PlayerGui"):WaitForChild("RoundUI")

local InventoryFrame = LobbyUI:WaitForChild("Inventory")
local AbilityTab = InventoryFrame.AbilityTab
local InfoFrame = AbilityTab.InfoFrame

local SFX = game:GetService("SoundService").SFX

local Knit = require(ReplicatedStorage.Packages.Knit)
local Shared = require(script.Parent.Parent.Shared)
local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)

local ShopService = Knit.GetService("ShopService")
local AbilityService = Knit.GetService("AbilityService")
local Workspace = game:GetService("Workspace")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")

local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")

local module = {}

local Connections = {}

local function CreateEquipConnection(abilityName)
    Connections["AbilityEquip"] = InfoFrame.Purchase.Button.MouseButton1Click:Connect(function()
        if ClickDebounce then
            return
        end
        ClickDebounce = true
        if InfoFrame.Purchase:GetAttribute("Type") == "Equip" then
            warn("Equip")
            AbilityService:EquipAbility(abilityName):andThen(function(Results)
                warn(Results)
                if Results == "Equipped" then
                    ChangePurchaseButton("Unequip")
                    SFX.Click:Play()
                else
                    SFX.Error:Play()
                end
            end)
        else
            warn("Unequip")

            AbilityService:UnequipAbility(abilityName):andThen(function(Results)
                warn(Results)
                if Results == "Unequipped" then
                    ChangePurchaseButton("Equip", abilityName)
                    SFX.Click:Play()
                else
                    SFX.Error:Play()
                end
            end)
        end

        task.wait(0.5)
        ClickDebounce = false
    end)
end

function ChangePurchaseButton(Type)
    if Type == "Equip" then
        InfoFrame.Purchase.TextLabel.Text = "Equip"
        InfoFrame.Purchase.BackgroundColor3 = Color3.fromRGB(121, 255, 72)
        InfoFrame.Purchase:SetAttribute("Type", "Equip")
    elseif Type == "Unequip" then
        InfoFrame.Purchase.TextLabel.Text = "Unequip"
        InfoFrame.Purchase.BackgroundColor3 = Color3.fromRGB(255, 72, 78)
        InfoFrame.Purchase:SetAttribute("Type", "Unequip")
        RoundUI.Hotbar.Ability.TextLabel.Text = "None"
    end
end

local function UpdateAbilitiesOwned()
	local TotalAbilities = 0
	local OwnedAbilities = 0

	for i, v in pairs(ShopData.Abilities) do
		TotalAbilities += 1
	end

	for i, v in pairs(PlayerProfileReplica.Data.Inventory.Abilities) do
		OwnedAbilities += 1
	end
	AbilityTab.MainFrame.AmountOwned.Text = OwnedAbilities .. "/" .. TotalAbilities .. " Owned"
end
function module:Setup()
	local Grid = AbilityTab.MainFrame.ScrollingFrame
	UpdateAbilitiesOwned()



	for abilityName, abilityInfo in pairs(ShopData.Abilities) do
		local abilityDisplay = Grid.SampleFrame:Clone()
		abilityDisplay.Parent = Grid
		abilityDisplay.Name = abilityName
		abilityDisplay.Title.Text = abilityName
		abilityDisplay.Visible = true
		abilityDisplay.Button.MouseButton1Click:Connect(function()
			if ClickDebounce then
				return
			end
			ClickDebounce = true
			SFX.Click:Play()
			InfoFrame.AbilityIcon.ImageLabel.Image = abilityInfo.Icon
			InfoFrame.AbilityName.Text = abilityName
			InfoFrame.Description.Text = abilityInfo.Description

			if PlayerProfileReplica.Data.Inventory.Abilities[abilityName] then --* If they own the ability
				-- ! Visualizing their upgrades
				for i, v in pairs(InfoFrame.Upgrades:GetChildren()) do
					if v:IsA("Frame") then
						v.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					end
				end
                
				for i = 1, PlayerProfileReplica.Data.Inventory.Abilities[abilityName].Upgrades do
					InfoFrame.Upgrades[i].BackgroundColor3 = Color3.fromRGB(21, 181, 255)
				end
				if PlayerProfileReplica.Data.Inventory.CurrentAbility ~= abilityName then
					ChangePurchaseButton("Equip")
                    RoundUI.Hotbar.Ability.TextLabel.Text = abilityName

				else
					ChangePurchaseButton("Unequip")
				end
				if Connections["AbilityEquip"] then
					Connections["AbilityEquip"]:Disconnect()
				end
                CreateEquipConnection(abilityName)
			else --* If they don't own the ability
				InfoFrame.Purchase.TextLabel.Text = "Purchase ($" .. abilityInfo.Price .. ")"
				if Connections["AbilityPurchase"] then
					Connections["AbilityPurchase"]:Disconnect()
				end
				Connections["AbilityPurchase"] = InfoFrame.Purchase.Button.MouseButton1Click:Connect(function()
					if ClickDebounce then
						return
					end
					ClickDebounce = true
					ShopService:PurchaseAbility(abilityName):andThen(function(Results)
						if Results == "Purchased" then
                            ChangePurchaseButton("Equip")
							SFX.Purchase:Play()
                            CreateEquipConnection(abilityName)
							Connections["AbilityPurchase"]:Disconnect()
						else
							--SFX.Error:Play()
						end
					end)
					task.wait(0.5)
					ClickDebounce = false
				end)
			end

			task.wait(0.5)
			ClickDebounce = false
		end)
	end
end

return module
