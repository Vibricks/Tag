local ReplicatedStorage = game:GetService("ReplicatedStorage")
local  Knit = require(ReplicatedStorage.Packages.Knit)
Knit.OnStart():await() --! We wait for knit to start first
local StatService = Knit.GetService("StatService")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")

local SoundService = game:GetService("SoundService")
local SFX = SoundService.SFX

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Camera = workspace.CurrentCamera


local SpectateUI = PlayerGui:WaitForChild("SpectateUI")
local Buttons = SpectateUI:WaitForChild("Buttons")

local module = {}


local Spectating = false
local SpectateConnections = {}
local SpectateList = {}
local Num = 1
local currentHumanoid




--! Functions 

function enableSpectateUI()
    Buttons.Spectate.Visible = true
    Buttons.Previous.Visible = false
    Buttons.Next.Visible = false
    SpectateUI.PlayerName.Visible = false

    SpectateUI.Enabled = true
end

function spectateNextPlayer()
    local nextPlr = SpectateList[1]
    if nextPlr then
        Num = 1
        Spectate()
    else
        EndSpectate()
    end
end

function removeFromSpectateList(Hum)
    local found = table.find(SpectateList, Hum)
    if found then
        table.remove(SpectateList, found)
    end
end

function Spectate()
    currentHumanoid = SpectateList[Num]
    Camera.CameraSubject = currentHumanoid
    SpectateUI.PlayerName.Text = currentHumanoid.Parent.Name
end

function EndSpectate()
    Camera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
    Spectating = false
    for i, v in pairs(SpectateConnections) do
        v:Disconnect()
    end
    Buttons.Previous.Visible = false
    Buttons.Next.Visible = false
    SpectateUI.PlayerName.Visible = false
    Buttons.Spectate.TextLabel.Text = "Spectate"
    Buttons.Spectate.BackgroundColor3 = Color3.fromRGB(205, 88, 255)
    if ReplicatedStorage.GameInfo.GameInProgress.Value == true then
        Buttons.Spectate.Visible = true
        SpectateUI.Enabled = true
    else
        SpectateUI.Enabled = false
    end
end

--! Connections

Buttons.Spectate.Button.MouseButton1Click:Connect(function()
    if game.Players.LocalPlayer:GetAttribute("InGame") then return end
    SFX.Click:Play()
    if Spectating == false then  
        if ReplicatedStorage.GameInfo.GameInProgress.Value == false then return end

        --* Getting the list of players currently playing
        for _, plr in pairs(game.Players:GetChildren()) do
            if plr:GetAttribute("InGame") and plr.Name ~= game.Players.LocalPlayer.Name then
                local Hum = plr.Character:WaitForChild("Humanoid")
                SpectateList[#SpectateList+1] = Hum

                SpectateConnections[plr.Name.."NoLongerInGame"] = plr:GetAttributeChangedSignal("InGame"):Connect(function()
                    removeFromSpectateList(Hum)
                    if currentHumanoid == Hum then spectateNextPlayer() end
                end)
            
                SpectateConnections[plr.Name.."Removing"] = plr.Character.AncestryChanged:Connect(function(child, parent)
                    removeFromSpectateList(Hum)
                    if parent ~= workspace then
                        if currentHumanoid == Hum then spectateNextPlayer() end
                    end
                end)
            end
        end
        if #SpectateList <= 0 then return end

        --* Spectating their humanoid
        Spectating = true
        Spectate()
        Buttons.Previous.Visible = true
        Buttons.Next.Visible = true
        SpectateUI.PlayerName.Visible = true
        Buttons.Spectate.TextLabel.Text = "Cancel"
        Buttons.Spectate.BackgroundColor3 = Color3.fromRGB(211, 61, 78)
    elseif Spectating == true then
        EndSpectate()
    end
end)

Buttons.Next.MouseButton1Click:Connect(function()
    Num += 1
    if Num > #SpectateList then
        Num = 1
    end
    print(Num)
    Spectate()
end)

Buttons.Previous.MouseButton1Click:Connect(function()
    Num -= 1
    if Num < 1 then
        Num = #SpectateList
    end
    print(Num)
    Spectate()
end)



ReplicatedStorage.GameInfo.GameInProgress:GetPropertyChangedSignal("Value"):Connect(function()
    if ReplicatedStorage.GameInfo.GameInProgress.Value == true and Player:GetAttribute("IsAFK") then
        enableSpectateUI()
    elseif ReplicatedStorage.GameInfo.GameInProgress.Value == false then
        SpectateUI.Enabled = false
        if Spectating then
            EndSpectate()
        end
    end
end)

if ReplicatedStorage.GameInfo.GameInProgress.Value == true then
    enableSpectateUI()
end




return module