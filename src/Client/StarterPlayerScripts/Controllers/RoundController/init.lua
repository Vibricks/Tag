local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerGui = Knit.Player:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundController = Knit.CreateController { Name = "RoundController" }


local GameInfo = ReplicatedStorage.GameInfo

local MainUI = PlayerGui:WaitForChild("MainUI")
local LobbyUI = PlayerGui:WaitForChild("LobbyUI")
local RoundUI = PlayerGui:WaitForChild("RoundUI")


function reflectServerMessage()
    local Message = GameInfo.ServerMessage.Value
    local Color = GameInfo.ServerMessage:GetAttribute("Color") or Color3.fromRGB(255, 255, 255)

    MainUI.ServerMessage.Text = Message
    MainUI.ServerMessage.TextColor3 = Color
end


function RoundController:KnitStart()
    reflectServerMessage()
    GameInfo.ServerMessage:GetPropertyChangedSignal("Value"):Connect(reflectServerMessage)
end


function RoundController:KnitInit()
	
end


return RoundController
