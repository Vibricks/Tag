local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Util = require(ReplicatedStorage.Shared.Util)
local StateReader = require(ReplicatedStorage.Shared.StateReader)
local Knit = require(ReplicatedStorage.Packages.Knit)
--local TaggerComponent = require(ServerScriptService.Components.Tagger)

local SFX = SoundService.SFX

local InputService = Knit.CreateService {
    Name = "InputService",
    Client = {
        ClientSlide = Knit.CreateSignal(),
        CancelClimbing = Knit.CreateSignal(),
    },
}

local StateManagerService
local AnimationService
local RoundService 

function InputService.Client:ToggleSprint(Player)
	local Character = Player.Character
	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")

    local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
    local IsSliding = StateManagerService:IsStateEnabled(Character, "Sliding")
    local IsLedgeGrabbing = StateManagerService:IsStateEnabled(Character, "LedgeGrabbing")
    local IsClimbing = StateManagerService:IsStateEnabled(Character, "Climbing")

    local IsSprintPaused =  Character:GetAttribute("PauseSprint")

    if not IsSprinting then
        if IsSliding or IsClimbing or IsLedgeGrabbing then return end
        StateManagerService:UpdateState(Character, "Sprinting", true)
        Character:SetAttribute("Sprinting", true)
        Humanoid.WalkSpeed = StateManagerService.Defaults.WalkSpeed + StateManagerService.Defaults.SPRINT_SPEED_INCREASE
        return true
    else
        StateManagerService:UpdateState(Character, "Sprinting", false)
        Character:SetAttribute("Sprinting", false)
        if not IsSliding and not IsLedgeGrabbing and not IsClimbing then
            Humanoid.WalkSpeed = StateManagerService.Defaults.WalkSpeed
        end
    end
end

function InputService.Client:ToggleSlide(Player, Bool, ExtraData)
	local Character = Player.Character
	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")

    local IsSliding = StateManagerService:IsStateEnabled(Character, "Sliding")
    local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
    local IsLedgeGrabbing = StateManagerService:IsStateEnabled(Character, "LedgeGrabbing")
    if not IsSprinting or IsLedgeGrabbing or Humanoid.FloorMaterial == Enum.Material.Air then return end

    local function EndSlide()
        if not Character:GetAttribute("Sliding") then return end
        --StateManagerService:SetCooldown(Character, "Sliding", 1)

        HRP.CanCollide = true
        Character:SetAttribute("Sliding", false)
        Character:SetAttribute("PauseSprint", false)
        local defaultSpeed = StateManagerService.Defaults.WalkSpeed
        local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
        Humanoid.JumpPower = StateManagerService.Defaults.JumpPower
        local SLIDE_SPEED_INCREASE = 30
        if IsSprinting and (not  ExtraData or ExtraData and  ExtraData.CancelType ~= "Jump") then
            --AnimationService:PlayAnimation(Humanoid, "Sprint")
            Humanoid.WalkSpeed = defaultSpeed + StateManagerService.Defaults.SPRINT_SPEED_INCREASE + SLIDE_SPEED_INCREASE
            task.delay(.35, function()
                local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")

                if IsSprinting then
                    Humanoid.WalkSpeed = defaultSpeed + StateManagerService.Defaults.SPRINT_SPEED_INCREASE
                else
                    Humanoid.WalkSpeed = defaultSpeed
                end
            end)
            --Humanoid.JumpPower = 0
        elseif IsSprinting then
            Humanoid.WalkSpeed = defaultSpeed + StateManagerService.Defaults.SPRINT_SPEED_INCREASE
        elseif not IsSprinting then
            Humanoid.WalkSpeed = defaultSpeed
            --Humanoid.JumpPower = 50
        end 
        if ExtraData and ExtraData.CancelType == "Jump" then

        end
        --task.wait(1)
        --Character:SetAttribute("SlideCooldown", false)
    end

    local SlideLifeTime = 1
    if Bool == true and not IsSliding and IsSprinting and not StateReader:IsOnCooldown(Character, "Sliding") then
        StateManagerService:SetCooldown(Character, "Sliding", 3.5)

        Character:SetAttribute("CanCancelSlide", false)
        Character:SetAttribute("PauseSprint", true)


        task.delay(.5, function()
            Character:SetAttribute("CanCancelSlide", true)
        end)
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
        HRP.CanCollide = false
        AnimationService:StopAnimation(Humanoid, "Sprint")
        AnimationService:PlayAnimation(Humanoid, "Slide")
        StateManagerService:UpdateState(Character, "Sliding", SlideLifeTime)
        Character:SetAttribute("Sliding", true)

        task.delay(SlideLifeTime, function()
            AnimationService:StopAnimation(Humanoid, "Slide")
            EndSlide()
        end)
        return true, SlideLifeTime
    elseif Bool == false and IsSliding then
        EndSlide()
    end
end

function InputService.Client:ToggleLedgeGrab(Player, Bool)
    local Character = Player.Character
	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")

    local IsSliding = StateManagerService:IsStateEnabled(Character, "Sliding")
    local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
    local IsLedgeGrabbing = StateManagerService:IsStateEnabled(Character, "LedgeGrabbing")

    if Bool == true and not IsLedgeGrabbing then
        Character:SetAttribute("PauseSprint", true)
        StateManagerService:ChangeSpeed(Character, 5, .2, 1)
        StateManagerService:UpdateState(Character, "LedgeGrabbing", true)
    elseif Bool == false and IsLedgeGrabbing then
        StateManagerService:UpdateState(Character, "LedgeGrabbing", false)
        Character:SetAttribute("PauseSprint", false)
    end
end

function InputService.Client:ToggleClimb(Player)
    local Character = Player.Character
	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")

    local IsSliding = StateManagerService:IsStateEnabled(Character, "Sliding")
    local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
    local IsLedgeGrabbing = StateManagerService:IsStateEnabled(Character, "LedgeGrabbing")
    local IsClimbing = StateManagerService:IsStateEnabled(Character, "Climbing")

    local function EndClimb()
        StateManagerService:UpdateState(Character, "Climbing", 0)
    end

    if not IsClimbing then
        StateManagerService:UpdateState(Character, "Climbing", 5)
    else
        EndClimb()
    end
end

function InputService.Client:VerifyHit(Player, Victim)
    local Character = Player.Character

	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")
    local VictimHum, VictimHRP = Victim:FindFirstChild("Humanoid"), Victim:FindFirstChild("HumanoidRootPart")
    if not Character or not Humanoid or  Humanoid.health <= 0 or not VictimHum or VictimHum.Health <= 0 then return end

    local IsSliding = StateManagerService:IsStateEnabled(Character, "Sliding")
    local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
    local IsAttacking = StateManagerService:IsStateEnabled(Character, "Attacking")
    local IsTagger = CollectionService:HasTag(Character, "Taggers")
    local GameInProgress = ReplicatedStorage.GameInfo.GameInProgress.Value

    local Magnitude = (HRP.Position - VictimHRP.Position).Magnitude
    if Magnitude <= 5 + 5 then
        RoundService.Signals.ProcessTagHit:Fire(Character, Victim) --! Attacker, Victim
    else
        warn(Player, "Has abnormally long range")
    end
end

function InputService.Client:RegisterSwing(Player)
    local Character = Player.Character
	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")
    if not Character or not Humanoid then return end
    local IsSliding = StateManagerService:IsStateEnabled(Character, "Sliding")
    local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
    local IsAttacking = StateManagerService:IsStateEnabled(Character, "Attacking")
    local LedgeGrabbing = StateManagerService:IsStateEnabled(Character, "LedgeGrabbing")
    local IsClimbing = StateManagerService:IsStateEnabled(Character, "Climbing")
    local CanAttack = StateManagerService:IsStateEnabled(Character, "CanAttack")
    local IsTagger = CollectionService:HasTag(Character, "Taggers")
    local GameInProgress = ReplicatedStorage.GameInfo.GameInProgress.Value
    StateManagerService:SetCooldown(Character, "Swinging", .5)

    if not IsAttacking and IsTagger and not IsSliding and GameInProgress and not LedgeGrabbing and CanAttack then
        --Util:PlaySoundAtPosition(SFX.swipe, HRP)
        StateManagerService:UpdateState(Character, "Attacking", 0.75)
        return true
    end
    return false
end

function InputService.Client:Vault(Player)
    local Character = Player.Character
	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")
    if not Character or not Humanoid then return end
    local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
    if IsSprinting then
        StateManagerService:ChangeSpeed(Character, 5, 0.4, 2, {DisableJump = true})
        StateManagerService:UpdateState(Character, "Vaulting", 0.75)
        task.wait(0.75)
        if StateManagerService:IsStateEnabled(Character, "Sprinting") then
            local Speed = StateManagerService.Defaults.WalkSpeed + StateManagerService.Defaults.SPRINT_SPEED_INCREASE + 30
            StateManagerService:ChangeSpeed(Character, Speed, .35, 2)
        end
    end
end



-- function InputService.Client:ProcessClick(Player)
--     if ReplicatedStorage.GameInfo.GameInProgress.Value == false then return end
--     local Character = Player.Character
-- 	local Humanoid,HRP = Character:FindFirstChild("Humanoid"),Character:FindFirstChild("HumanoidRootPart")
--     if not Character or not Humanoid then return end
--     local IsSliding = StateManagerService:IsStateEnabled(Character, "Sliding")
--     local IsSprinting = StateManagerService:IsStateEnabled(Character, "Sprinting")
--     local IsAttacking = StateManagerService:IsStateEnabled(Character, "Attacking")
--     local IsTagger = CollectionService:HasTag(Character, "Taggers")
--     if not IsAttacking and IsTagger and not IsSliding then

--         local TaggerObject = TaggerComponent:FromInstance(Character)
--         if TaggerObject then
--             StateManagerService:UpdateState(Character, "Attacking", 1)
--             AnimationService:PlayAnimation(Humanoid, "Slap", {Priority = Enum.AnimationPriority.Action2, Speed = 2})
--             task.wait(.25)
--             --Character:SetAttribute("Swinging", true)
--             TaggerObject:ToggleHitDetection(true)
--             Util:PlaySoundInPart(SFX.swipe, HRP)
--             task.wait(.5)
--             --Character:SetAttribute("Swinging", false)
--             TaggerObject:ToggleHitDetection(false)
--         end
--     end

-- end

function InputService:KnitStart()
    
end


function InputService:KnitInit()
    StateManagerService = Knit.GetService("StateManagerService")
    AnimationService = Knit.GetService("AnimationService")
    RoundService = Knit.GetService("RoundService")
end


return InputService
