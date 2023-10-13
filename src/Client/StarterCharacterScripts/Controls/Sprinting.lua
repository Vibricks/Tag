local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.OnStart():await()

local InputService = Knit.GetService("InputService")
local AnimationController = Knit.GetController("AnimationController")
local StateReader = require(ReplicatedStorage.Shared.StateReader)
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")


local module = {}

function module:BeginSprint(ShiftSprint)
    if ShiftSprint and PlayerProfileReplica.Data.Settings.AutoSprint then return end
    InputService:ToggleSprint():andThen(function(Verified)
        if Verified == true then
            local SprintAnim = AnimationController:GetAnimation("Sprint")
            SprintAnim:Play()
            while StateReader:IsStateEnabled(Character, "Sprinting") do
                if Humanoid.Health <= 0 then return end

                if Humanoid.MoveDirection == Vector3.new()then
                    SprintAnim:Stop()
                    if not ShiftSprint then
                        module:EndSprint()
                    end
                else
                if  SprintAnim.IsPlaying == false and not Character:GetAttribute("PauseSprint") then
                    SprintAnim:Play()
                end 
                end
                RunService.RenderStepped:Wait()
            end
            SprintAnim:Stop()

        end
    end)
end

function module:EndSprint(ShiftSprint)
    if ShiftSprint and PlayerProfileReplica.Data.Settings.AutoSprint then return end
    InputService:ToggleSprint()
end

local AutoSprintConnection

function AutoSprint(bool) --! first argument = old value
    if AutoSprintConnection then AutoSprintConnection:Disconnect() end
    if StateReader:IsStateEnabled(Character, "Sprinting") then
        module:EndSprint()
    end
    if bool == true then
        AutoSprintConnection = Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
            if Humanoid.Health <= 0 then return end
            local AutoSprint = PlayerProfileReplica.Data.Settings.AutoSprint
            if Humanoid.MoveDirection.Magnitude >= 0.01 and not StateReader:IsStateEnabled(Character, "Sprinting") and AutoSprint then -->> you are walking
                module:BeginSprint()
        -- elseif Humanoid.MoveDirection.Magnitude < 0.01 and StateReader:IsStateEnabled(Character, "Sprinting") and AutoSprint then
            end 
        end)
    end
end

if PlayerProfileReplica.Data.Settings.AutoSprint then
    AutoSprint(true)
end

PlayerProfileReplica:ListenToChange({"Settings", "AutoSprint"}, AutoSprint)-- ! This passes newValue to the function


--! Sprint Camera
local function updateBobbleEffect(deltaTime)
    local currentTime = tick()
    local IsLedgeGrabbing = StateReader:IsStateEnabled(Character, "LedgeGrabbing")
    local IsSprinting = StateReader:IsStateEnabled(Character, "Sprinting")
    local smoothening = 0.2

    if Humanoid.MoveDirection.Magnitude > 0 and IsSprinting and not IsLedgeGrabbing then -- we are walking
        local bobbleX = math.cos(currentTime * 10) * 0.35
        local bobbleY = math.abs(math.sin(currentTime * 10)) * 0.35

        local bobble = Vector3.new(bobbleX, bobbleY, 0)

        Humanoid.CameraOffset =
        Humanoid.CameraOffset:lerp(bobble, math.clamp(smoothening * deltaTime * 60, 0, 1))
    else -- we are not walking
        Humanoid.CameraOffset = Humanoid.CameraOffset * 0.75
    end
end

RunService.RenderStepped:Connect(updateBobbleEffect)

return module