local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local PlayerGui = Player:WaitForChild("PlayerGui")
local LobbyUI = PlayerGui:WaitForChild("LobbyUI")
local SpinUI = PlayerGui:WaitForChild("SpinUI")

local ShopData = require(ReplicatedStorage.Shared.Metadata.ShopData)
local Util = require(ReplicatedStorage.Shared.Util)

local SFX = game:GetService("SoundService").SFX

local Templates = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI")

local Trove = require(ReplicatedStorage.Packages.Trove)



local module = {}
module.ConnectionTrove = Trove.new()
module.CurrentFrame = nil

function tweenGraph(x, pow)
    x = math.clamp(x, 0, 1)
    return 1 - (1-x)^pow
end

function module:setViewport(viewportFrame, Object)
    local itemModel = Instance.new("Model")

    for _, child in pairs(Object:GetChildren()) do
        if not (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("Sound")) then
            child:Clone().Parent = itemModel
        end
    end

    itemModel:PivotTo(CFrame.new() * CFrame.Angles(math.rad(-39), 0, 0))

    itemModel.Parent = viewportFrame

    local currentCamera = Instance.new("Camera")
    currentCamera.CFrame = CFrame.new(Vector3.new(-itemModel:GetExtentsSize().Y*0.9, 0, 0), itemModel:GetPivot().Position + Vector3.new(0, -0.1, 0))
    currentCamera.Parent = viewportFrame
    viewportFrame.CurrentCamera = currentCamera
end

function module:createWeaponDisplay(Weapon: Instance, Rarity: string, Sort)
    if type(Weapon) == "string" then Weapon = ReplicatedStorage.Assets.Weapons:FindFirstChild(Weapon, true) end
    local Rarity = Rarity or Weapon.Parent.Name
    local Display = Templates.WeaponDisplay:Clone()
    Display.Name = Weapon.Name
    Display.Owned.Visible = false
    Display.Visible = true
    Display.Title.Text = Weapon.Name
    Display.Title.TextColor3 = ShopData.RarityColors[Rarity]
    Display.BackgroundColor3 = ShopData.RarityColors[Rarity]
    self:setViewport(Display.ItemViewport, Weapon:Clone())
    if Sort == "Rarity" then
        if Rarity == "Common" then 
            Display.LayoutOrder = 1
        elseif Rarity == "Rare" then
            Display.LayoutOrder = 2
        elseif Rarity == "Legendary" then
            Display.LayoutOrder = 3
        else 
            warn("None of the above")
            Display.LayoutOrder = 4
        end
    end
    return Display
end



function module:Spin(SelectedItem, SpinData, unboxTime)
    local numItems = Random.new():NextInteger(20, 100)
    local chosenPosition = Random.new():NextInteger(15, numItems-5)
    local finalRarity = SelectedItem.Parent.Name
    local chosenFrame
    for i = 1, numItems do
        local rarityChosen = SelectedItem.Parent.Name
        local displayItem = SelectedItem

    
        if i ~= chosenPosition then
            local rndChance = Random.new():NextNumber() * 100
            local Weight = 0
            
            for rarity, percentage in pairs(SpinData.Rates) do
                Weight += percentage
                if rndChance <= Weight then
                    rarityChosen = rarity
                    break
                end
            end

            --* Getting the weapons we can potentially obtain from this spin
            local unboxableItems = {}
            for _, weapons in pairs(SpinData.CurrentStock) do
                for i = 1, #weapons do
                    table.insert(unboxableItems, weapons[i])
                end
            end

            --* Shuffling the weapons 
            for i = #unboxableItems, 2, -1 do
                local j = Random.new():NextInteger(1, i)
                unboxableItems[i], unboxableItems[j] = unboxableItems[j], unboxableItems[i]
            end
            
            for _, itemName in pairs(unboxableItems) do
                if SpinData.Storage:FindFirstChild(itemName, true).Parent.Name == rarityChosen then
                    displayItem = SpinData.Storage:FindFirstChild(itemName, true)
                    break
                end
            end
        end

        		
		-- local newItemFrame = SpinUI.SpinFrame.Slider.SampleFrame:Clone()
        -- newItemFrame.Name = displayItem.Name
        -- newItemFrame.ImageLabel.Visible = false
        -- newItemFrame.Owned.Visible = false
        -- newItemFrame.Visible = true
        -- newItemFrame.Title.Text = displayItem.Name
		-- newItemFrame.BackgroundColor3 = ShopData.RarityColors[rarityChosen]
        -- self:setViewport(newItemFrame.ItemViewport, displayItem)
        local DisplayFrame = self:createWeaponDisplay(displayItem, rarityChosen)

        if displayItem == SelectedItem then chosenFrame = DisplayFrame end
		DisplayFrame.Parent = SpinUI.SpinFrame.Slider
    end

    SpinUI.SpinFrame.Slider.Position = UDim2.new(0, 0, 0.5, 0)
	
	local cellSize = SpinUI.SpinFrame.Slider.SampleFrame.Size.X.Scale
	local padding = SpinUI.SpinFrame.Slider.UIListLayout.Padding.Scale
	local pos1 = 0.5 - cellSize/2
	local nextOffset = -cellSize - padding
	
	local posFinal = pos1 + (chosenPosition-1) * nextOffset
	local rndOffset = Random.new():NextNumber(-cellSize/2, cellSize/2)
	posFinal += rndOffset
    

    local timeOpened = tick()

	
	local pow = 3--Random.new():NextNumber(2, 10)
	local lastSlot = 0
	SpinUI.ItemName.Title.Text = "Spinning..."
    --SpinUI.ItemRarity.Title.Text = "Rarity"
    --SpinUI.ItemRarity.Title.TextColor3 = Color3.fromRGB(255,255,255)
   -- SpinUI.SpinFrame.Cover.Visible = true
    SpinUI.ItemName.Title.TextColor3 = Color3.fromRGB(255,255,255)
	while true do
		local timeSinceOpened = tick() - timeOpened
		local x = timeSinceOpened / (5)
		
		local t = tweenGraph(x, pow)
		local newXPos = Util:Lerp(0, posFinal, t)
		
		local currentSlot = math.abs(math.floor((newXPos+rndOffset)/cellSize))+1
		if currentSlot ~= lastSlot then
			SFX.TickSound:Play()
			lastSlot = currentSlot
		end
		
		SpinUI.SpinFrame.Slider.Position = UDim2.new(newXPos, 0, 0.5, 0)
		
		if x >= 1 then
			break
		end
		
		game:GetService("RunService").Heartbeat:Wait()
	end

    SpinUI.ItemName.Title.Text = SelectedItem.Name
    --SpinUI.ItemRarity.Title.Text = finalRarity
    SpinUI.ItemName.Title.TextColor3 = ShopData.RarityColors[finalRarity]
    SFX.Shine:Play()
   -- SpinUI.SpinFrame.Cover.Visible = false
    chosenFrame.ZIndex = 4
    task.wait(2)
    module.CurrentFrame = nil
    game.Lighting.UI_BLUR.Enabled = false

    SpinUI.Enabled = false
end



Humanoid.Died:Connect(function()
    module.ConnectionTrove:Destroy()
end)

return module