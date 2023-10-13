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

local spectate = TopBarPlus.new()
--:setImage("rbxassetid://10248876343")
:setLabel("Spectate")


afk.toggled:Connect(function(isSelected)
    RoundService:ToggleAFK()
end)

local Spectating = false
local SpectateConnections = {}
local SpectateList = {}
local Num = 1
local currentHumanoid

spectate.toggled:Connect(function()
    if game.Players.LocalPlayer:GetAttribute("InGame") then return end
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

    elseif Spectating == true then
        EndSpectate()
    end
end)
ReplicatedStorage.GameInfo.GameInProgress:GetPropertyChangedSignal("Value"):Connect(function()
    if Spectating then
        EndSpectate()
    end
end)


--? Functions not sure where else to put em xD

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
end

function EndSpectate()
    Camera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
    Spectating = false
    for i, v in pairs(SpectateConnections) do
        v:Disconnect()
    end
end