local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local StateReader = require(ReplicatedStorage.Shared.StateReader)

local CooldownController = Knit.CreateController { Name = "CooldownController" }
local ReplicaInterfaceController
local StateProfileReplica

local PlayerGui --= Knit.Player:WaitForChild("PlayerGui")
local RoundUI 

local Character

local TweenCache = {}

local function TweenCooldownShade(CooldownShade, Duration)
    if TweenCache[CooldownShade] then TweenCache[CooldownShade]:Cancel() TweenCache[CooldownShade] = nil end
    CooldownShade.Size = UDim2.fromScale(1,1)
    CooldownShade.Position = UDim2.fromScale(0,0)

    CooldownShade.Visible = true

    local tweenInfo = TweenInfo.new(Duration, Enum.EasingStyle.Quad)
    TweenCache[CooldownShade] = TweenService:Create(CooldownShade, tweenInfo, {Size = UDim2.fromScale(1,0), Position = UDim2.fromScale(0,1)})
    TweenCache[CooldownShade]:Play()
end

local CooldownUIFunctions = {
    ["Swinging"] = function(CooldownInfo)
        local CooldownShade = RoundUI.Hotbar.Tag.CooldownShade
        TweenCooldownShade(CooldownShade, CooldownInfo.Duration)
     
        task.delay(CooldownInfo.Duration, function()
            if not StateReader:IsOnCooldown(Character, "Swinging") then
                CooldownShade.Visible = false
            end
        end) 
    end,
    ["Sliding"] = function(CooldownInfo)
        local CooldownShade = RoundUI.Hotbar.Slide.CooldownShade
        TweenCooldownShade(CooldownShade, CooldownInfo.Duration)
        task.delay(CooldownInfo.Duration, function()
            if not StateReader:IsOnCooldown(Character, "Sliding") then
                CooldownShade.Visible = false
            end
        end) 
    end,
    ["Ability"] = function(CooldownInfo)
        local CooldownShade = RoundUI.Hotbar.Ability.CooldownShade
        TweenCooldownShade(CooldownShade, CooldownInfo.Duration)
        task.delay(CooldownInfo.Duration, function()
            if not StateReader:IsOnCooldown(Character, "Ability") then
                CooldownShade.Visible = false
            end
        end) 
    end,

}

local function ListenToCooldowns()
    Character = Knit.Player.Character
    StateProfileReplica = ReplicaInterfaceController:GetReplica("StateProfile")

    StateProfileReplica:ListenToNewKey({"Cooldowns"}, function(oldValue, newKey)
        local CooldownName = newKey
        local Duration
        StateProfileReplica:ListenToChange({"Cooldowns", newKey, "StartTime"}, function(oldValue, newValue)--!We listen to duration because it's the last to change meaning we'll have all the updated values by then
            task.wait()
            local StartTime = StateProfileReplica.Data.Cooldowns[CooldownName].StartTime
            local Duration = StateProfileReplica.Data.Cooldowns[CooldownName].Duration
           -- Duration = newValue or oldValue --!not sure why but it's always oldvalue on the first instance the cooldown is used
           --warn(Duration)
           --warn(StartTime, Duration)
           if CooldownUIFunctions[CooldownName] then
                CooldownUIFunctions[CooldownName](StateProfileReplica.Data.Cooldowns[CooldownName])
           end
        end)
    end)
end

function CooldownController:KnitStart()
    PlayerGui = Knit.Player:WaitForChild("PlayerGui")
    RoundUI = PlayerGui:WaitForChild("RoundUI")

    if Knit.Player.Character then ListenToCooldowns() end
    Knit.Player.CharacterAdded:Connect(function(character)
        PlayerGui = Knit.Player:WaitForChild("PlayerGui")
        RoundUI = PlayerGui:WaitForChild("RoundUI")
        ListenToCooldowns()
    end)
end


function CooldownController:KnitInit()
    ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
end


return CooldownController
