local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local TopBarPlus = require(ReplicatedStorage.Packages.TopbarPlus)
local Controller = require(ReplicatedStorage.Packages._Index["etheroit_topbarplus@1.0.1"].topbarplus.IconController)

Knit.OnStart():await()

local RoundService = Knit.GetService("RoundService")
local Camera = workspace.CurrentCamera

Controller.voiceChatEnabled = true
local icon = TopBarPlus.new()
            :setImage("rbxassetid://14946183140")
            :setRight()
            :setLabel("Info")

            
local afk = TopBarPlus.new()
:setLabel("AFK")


afk.toggled:Connect(function(isSelected)
    RoundService:ToggleAFK()
end)
