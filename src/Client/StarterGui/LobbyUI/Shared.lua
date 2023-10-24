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

function module:createWeaponDisplay(Weapon: Instance, Rarity: string, Sort: string)
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
local ThumbnailType = Enum.ThumbnailType.HeadShot
local ThumbnailSize = Enum.ThumbnailSize.Size420x420
local Thumbnail =  game.Players:GetUserThumbnailAsync(Player.UserId,ThumbnailType, ThumbnailSize)

_G.PlrThumbnail = Thumbnail

function module:createTitleDisplay(TitleHolder: Instance, Rarity: string, Sort: string)
    if type(TitleHolder) == "string" then TitleHolder = ReplicatedStorage.Assets.Titles:FindFirstChild(TitleHolder, true) end
    if TitleHolder.Name == "IgnorePart" then return end
    local Rarity = Rarity or TitleHolder.Parent.Name
    local Display = Templates.TitleDisplay:Clone()
    Display.Name = TitleHolder.Name
    Display.Owned.Visible = false
    Display.Visible = true
    Display.Title.Text = TitleHolder.Title.TextLabel.Text
    Display.Title.TextColor3 = TitleHolder.Title.TextLabel.TextColor3
    if TitleHolder.Title.TextLabel:FindFirstChild("UIGradient") then
        TitleHolder.Title.TextLabel.UIGradient:Clone().Parent = Display.Title
    end
    Display.BackgroundColor3 = ShopData.RarityColors[Rarity]
    Display.PlrThumbnail.Image = Thumbnail

    local particles = TitleHolder:FindFirstChildOfClass("ParticleEmitter") 
    if particles then
        Display.AuraIcon.Visible = true
        Display.AuraIcon.Image = particles.Texture
    end
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



function module:Spin(SelectedItem: Instance, SpinData: table, unboxTime: number)
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

            --* Getting the items we can potentially obtain from this spin
            local unboxableItems = {}
            for _, weapons in pairs(SpinData.CurrentStock) do
                for i = 1, #weapons do
                    table.insert(unboxableItems, weapons[i])
                end
            end

            --* Shuffling the items 
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

        local DisplayFrame
        if displayItem:FindFirstChild("Title") then
            DisplayFrame = self:createTitleDisplay(displayItem, rarityChosen)

        else
            DisplayFrame = self:createWeaponDisplay(displayItem, rarityChosen)
        end

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
	
	local pow = 3
	local lastSlot = 0
	SpinUI.ItemName.Title.Text = "Spinning..."

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
    SpinUI.ItemName.Title.TextColor3 = ShopData.RarityColors[finalRarity]
    SFX.Shine:Play()
    chosenFrame.ZIndex = 4

    local copiedGradient
    if SelectedItem:FindFirstChild("Title") then
        SpinUI.ItemName.Title.TextColor3 = SelectedItem.Title.TextLabel.TextColor3
        if SelectedItem.Title.TextLabel:FindFirstChild("UIGradient") then
            copiedGradient =  SelectedItem.Title.TextLabel:FindFirstChild("UIGradient"):Clone()
            copiedGradient.Name = "CustomGradient"
            copiedGradient.Parent = SpinUI.ItemName.Title
        end
    end


    task.wait(2)
    module.CurrentFrame = nil
    game.Lighting.UI_BLUR.Enabled = false
    if copiedGradient then 
        copiedGradient:Destroy()
    end
    SpinUI.Enabled = false
end



Humanoid.Died:Connect(function()
    module.ConnectionTrove:Destroy()
end)

return module