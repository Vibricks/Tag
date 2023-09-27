local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)

local Util = require(ReplicatedStorage.Shared.Util)
local MagnitudeHitbox = require(ReplicatedStorage.Shared.Hitboxes.MagnitudeHitbox)

local SFX = SoundService.SFX

local AnimationController
local InputService 
Knit.OnStart():andThen(function()
    AnimationController = Knit.GetController("AnimationController")
    InputService = Knit.GetService("InputService")
end)

local OnlyThisClient = {}

function OnlyThisClient.ShouldConstruct(component)
    local bool = component.Instance == Players.LocalPlayer.Character
    warn("Should extend", bool)
    return bool
end


local module = Component.new({
    Tag = "Chasers",
    Extensions =  {OnlyThisClient}

})

local SwingDebounce
function module:Swing()
    local Character = self.Instance
    local Humanoid = Character:FindFirstChild("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP or not Humanoid or (Humanoid and Humanoid.Health <= 0) then return end

    local IsSliding = Character:GetAttribute("Sliding")
    if ReplicatedStorage.GameInfo.GameInProgress.Value == false then return end
    if not SwingDebounce and not IsSliding and not Character:GetAttribute("LedgeGrabbing") then
        local SwingRegistered = InputService:RegisterSwing()
        SwingDebounce = true
        AnimationController:PlayAnimation("Slap", {Priority = Enum.AnimationPriority.Action2, Speed = 2})
        task.wait(.25) --TODO switch this out for keyframe Reached
        Util:PlaySoundInPart(SFX.swipe, HRP)
        local HitVictims = {}
        local HitboxPerFrame
        HitboxPerFrame = RunService.RenderStepped:Connect(function(deltaTime)
            local HitboxInfo = {
                Character = Character,
                Range = 3,
                MultipleVictims = false,
            }
            local HitResult, Victim = MagnitudeHitbox(HitboxInfo)
            if HitResult and not HitVictims[Victim] then
                print("We hit", Victim.Name)
                HitVictims[Victim] = true
                InputService:VerifyHit(Victim)
                HitboxPerFrame:Disconnect()
            end
        end)
        --! Hit detection here
        task.wait(.5)
        HitboxPerFrame:Disconnect()
        SwingDebounce = false
    end
end



function module:Construct()
    warn("Constructing Chaser Component")
    print(self.Instance)
    local Player = game.Players.LocalPlayer
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local RoundUI = PlayerGui:WaitForChild("RoundUI")
    local Hotbar = RoundUI.Hotbar

    Hotbar.Slide.LayoutOrder = 1
    Hotbar.Ability.LayoutOrder = 3
    Hotbar.Tag.Visible = true

    self.tagButton = Hotbar.Tag
end

function module:Start()
end

function module:Stop()
    self.tagButton.Visible = false
end

function module:HeartbeatUpdate(dt)
end

function module:SteppedUpdate(dt)
end

function module:RenderSteppedUpdate(dt)
end

return module