local ReplicatedStorage = game:GetService("ReplicatedStorage")
local  Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await() --! We wait for knit to start first
local StatService = Knit.GetService("StatService")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")

local SoundService = game:GetService("SoundService")

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local LobbyUI = PlayerGui:WaitForChild("LobbyUI")
local MainButtons = LobbyUI:WaitForChild("Buttons")

local SFX = SoundService.SFX


local Connections = {}
local FrameModuleCache = {}

local Shared = require(script.Shared)
local Util = require(ReplicatedStorage.Shared.Util)

local function DisconnectFrameConnections(FrameName: string)
    Shared.CurrentFrame = nil
    for i, v in pairs(Connections[FrameName]) do
        v:Disconnect()
    end
end


for i, v in pairs(script:GetChildren()) do
    if v:IsA("ModuleScript") and v.Name ~= "Shared" then
        FrameModuleCache[v.Name] = require(v)
    end
end

for i, v in pairs(MainButtons:GetChildren()) do
    local Button = v:FindFirstChild("Button")
    if v:IsA("Frame") and  Button then

        Button.MouseButton1Click:Connect(function()
            SFX.Click:Play()
            local Frame = LobbyUI:FindFirstChild(v.Name)
            if not Frame then return end

            if Shared.CurrentFrame and Shared.CurrentFrame ~= Frame then
                FrameModuleCache[Shared.CurrentFrame.Name]:Toggle(false) --* Disable any opened frame
            end

            if Frame ~= Shared.CurrentFrame then 
                FrameModuleCache[Frame.Name]:Toggle(true)
                game.Lighting.UI_BLUR.Enabled = true
            else --* If the current frame is already our opened frame then
                FrameModuleCache[Shared.CurrentFrame.Name]:Toggle(false) --* Disable the current frame
                game.Lighting.UI_BLUR.Enabled = false
            end
        end)
    end
end






function ReflectLevel()
    local Level = PlayerProfileReplica.Data.Level
    PlayerGui:WaitForChild("LobbyUI").Level.TextLabel.Text = "Level "..Level
    ReflectExp()
    ReflectSp()
end

function ReflectExp()
    local ExpBar = PlayerGui:WaitForChild("LobbyUI").ExpBar
    local Level = PlayerProfileReplica.Data.Level
    local Current = PlayerProfileReplica.Data.Exp

    local Max = Util:CalculateMaxExp(Level)
    ExpBar.Current.Text = Current
    ExpBar.Max.Text = Max
    --ExpBar.Bar.Size = UDim2.fromScale(Current/Max, 1)
    ExpBar.Bar:TweenSize(UDim2.fromScale(Current/Max, 1), "Out", "Quad", .4, true)
end

function ReflectCash()
    local Cash = PlayerProfileReplica.Data.Cash
    PlayerGui:WaitForChild("LobbyUI").Cash.TextLabel.Text = "$ "..Cash
end

function ReflectSp()
    local StatPoints = PlayerProfileReplica.Data.StatPoints
    PlayerGui:WaitForChild("LobbyUI").Inventory.AbilityTab.MainFrame.StatPoints.Text = "Stat Points: "..StatPoints
end

ReflectExp()
ReflectLevel()
ReflectCash()
ReflectSp()

PlayerProfileReplica:ListenToChange({"Level"}, ReflectLevel)
PlayerProfileReplica:ListenToChange({"Exp"}, ReflectExp)
PlayerProfileReplica:ListenToChange({"Cash"}, ReflectCash)
