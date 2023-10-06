task.wait()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TextChatService: TextChatService = game:GetService("TextChatService")

-- variables
local textChannels: Folder = TextChatService:WaitForChild("TextChannels", 100) :: Folder
local systemChannel: TextChannel = textChannels:WaitForChild("RBXSystem", 100) :: TextChannel


local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerGui = Knit.Player:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundController = Knit.CreateController { Name = "RoundController" }

local RoundService

local SFX = SoundService.SFX

local GameInfo = ReplicatedStorage.GameInfo

local AnnouncementUI = PlayerGui:WaitForChild("AnnouncementUI")
local RoundUI = PlayerGui:WaitForChild("RoundUI")
local ResultsUI = PlayerGui:WaitForChild("ResultsUI")
local LobbyUI = PlayerGui:WaitForChild("LobbyUI")

function reflectServerMessage()
    local Message = GameInfo.ServerMessage.Value
    local Color = GameInfo.ServerMessage:GetAttribute("Color") or Color3.fromRGB(255, 255, 255)

    AnnouncementUI.ServerMessage.Text = Message
    AnnouncementUI.ServerMessage.TextColor3 = Color
end

function GameResultsScreen()
    
end


function RoundController:KnitStart()
    reflectServerMessage()
    GameInfo.ServerMessage:GetPropertyChangedSignal("Value"):Connect(reflectServerMessage)
    RoundService.GameOver:Connect(function(MatchResults)
        RoundUI.Enabled = false
        LobbyUI.Enabled = true
        --warn(MatchResults)
        if MatchResults and MatchResults.Winner then
            SFX.GameOver:Play()

            local UI = ResultsUI:Clone()
            game.Debris:AddItem(UI, 6)
            UI.Enabled = true
            UI.WinnerAnnouncement.Text = MatchResults.CustomWinText or "Winners: "..MatchResults.Winner
            UI.WinnerAnnouncement.TextColor3 = MatchResults.TeamColor
            local MVP = MatchResults.MVP
            if MatchResults.WIN_TYPE == "ONE_MVP" then
                
                local mvpFrame =  UI.OneMVP
                local thumbanilFrame = mvpFrame.Frame.CanvasGroup
                if MVP then
                    local Thumbnail = MatchResults.Thumbnail
                    thumbanilFrame.ImageLabel.Image = Thumbnail
                    thumbanilFrame.ImageLabel.Visible = true
                    thumbanilFrame.QuestionMark.Visible = false
                    mvpFrame.Frame.MVP_NAME.Text = MVP.Name
                else
                    thumbanilFrame.ImageLabel.Visible = false
                    thumbanilFrame.QuestionMark.Visible = true
                    mvpFrame.Frame.MVP_NAME.Text = "No One"
                end
            end
            UI.Parent = PlayerGui
        end
    end)

    RoundService.ReflectOnUI:Connect(function(Request, ExtraData)
        if Request == "EnableRoundUI" then
            RoundUI.Enabled = true
            LobbyUI.Enabled = false
        elseif Request == "TagLog" then
            local TaggerName = ExtraData[1]
            local VictimName = ExtraData[2]
            local RealMessage = TaggerName.." Tagged "..VictimName.."!"

            local Color = Color3.fromRGB(255, 100, 100)
            -- using math.floor so no floats ruin the message.
            local r: number = math.floor(Color.R * 255)
            local g: number = math.floor(Color.G * 255)
            local b: number = math.floor(Color.B * 255)

            local SystemMessage = "<font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. RealMessage .. "</font>"
            systemChannel:DisplaySystemMessage(SystemMessage)
        elseif Request == "YouWereTagged" then
            local taggedUI = PlayerGui.YouWereTagged:Clone()
            taggedUI.Enabled = true
            taggedUI.Message.Position = UDim2.fromScale(0.5,-1.5)
            taggedUI.Message2.Position = UDim2.fromScale(0.5,-1.5)
            --UDim2.fromScale(0.5,0.391)
            taggedUI.Parent = PlayerGui
            SFX.YouDied:Play()

            taggedUI.Message:TweenPosition(UDim2.fromScale(0.5,0.391), "Out", "Quad", .4, true)
            taggedUI.Message2:TweenPosition(UDim2.fromScale(0.5,0.527), "Out", "Quad", .4, true)
            task.wait(1.5)
            taggedUI.Message:TweenPosition(UDim2.fromScale(0.5,-1.5), "Out", "Quad", .4, true)
            taggedUI.Message2:TweenPosition(UDim2.fromScale(0.5,-1.5), "Out", "Quad", .4, true)
            game.Debris:AddItem(taggedUI, 1.5)
        end
    end)
end


function RoundController:KnitInit()
	RoundService = Knit.GetService("RoundService")
    local RealMessage = "Welcome to Tag!"

    local Color = Color3.fromRGB(255, 255, 101)
    -- using math.floor so no floats ruin the message.
    local r: number = math.floor(Color.R * 255)
    local g: number = math.floor(Color.G * 255)
    local b: number = math.floor(Color.B * 255)

    local SystemMessage = "<font color='rgb(" .. r .. "," .. g .. "," .. b .. ")'>" .. RealMessage .. "</font>"
    systemChannel:DisplaySystemMessage(SystemMessage)
end


return RoundController
