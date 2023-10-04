local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TopBarPlus = require(ReplicatedStorage.Packages.TopbarPlus)
local Controller = require(ReplicatedStorage.Packages._Index["etheroit_topbarplus@1.0.1"].topbarplus.IconController)
Controller.voiceChatEnabled = true
local icon = TopBarPlus.new()
            :setImage("rbxassetid://14946183140")
            :setRight()
            :setLabel("Info")

            
local afk = TopBarPlus.new()
:setLabel("AFK")

local spectate = TopBarPlus.new()
--:setImage("rbxassetid://10248876343")
:setLabel("Spectate")
