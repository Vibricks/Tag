local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local Animator = Humanoid:WaitForChild("Animator")
local Camera = workspace.CurrentCamera

local Promise = require(ReplicatedStorage.Packages.Promise)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Util = require(ReplicatedStorage.Shared.Util)
local Component = require(ReplicatedStorage.Packages.Component)

local LedgeGrabbing = require(script.Climbing)

local BeginAcceleration = Signal.new()

local RoundService 
local InputService 
local AnimationController 
local TaggerComponent
Knit.OnStart():andThen(function()
    RoundService = Knit.GetService("RoundService")
    InputService = Knit.GetService("InputService")
    AnimationController = Knit.GetController("AnimationController")
    TaggerComponent =  require(StarterPlayerScripts.Components.Tagger)
end)

local Connections = {}
-- local MovementStates = {
--     Walking = false,
--     Sliding = false,
-- }
-- local CurrentSpeed = 12
-- local MaxSpeed = 28
-- local LastUpdate = os.clock()
-- local Connections = {} 
-- local TopSpeed = false
-- BeginAcceleration:Connect(function()
--     Connections["Accleration"] = RunService.RenderStepped:Connect(function()
--         if MovementStates["Sliding"] then 
--             SprintAnim:Stop()
--             Connections["Accleration"]:Disconnect()
--             Connections["Accleration"] = nil 
--             return
--         end

--         if MovementStates["Walking"] and CurrentSpeed < MaxSpeed and os.clock() - LastUpdate >= .5 then
--             CurrentSpeed += 6
--             CurrentSpeed = math.clamp(CurrentSpeed, 12, MaxSpeed)
--             Humanoid.WalkSpeed = CurrentSpeed
--             LastUpdate = os.clock()
--         end
--         if CurrentSpeed >= MaxSpeed then
--             TopSpeed = true
--             local ZoomOut = TweenService:Create(Camera, TweenInfo.new(.4), {FieldOfView = 90})
--             ZoomOut:Play()
--             ZoomOut:Destroy()
--             SoundService.SFX.TopSpeedWoosh:Play()

--             warn("Top Speed Reached, Disconnecting")
--             Connections["Accleration"]:Disconnect()
--             Connections["Accleration"] = nil 
--             SprintAnim:Play()
--             SprintAnim:AdjustSpeed(2)
--         end
--     end)
-- end)


-- Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
--     if Humanoid.MoveDirection.Magnitude >= 0.01 and not MovementStates["Walking"] and not MovementStates["Sliding"] then -->> you are walking
--         MovementStates["Walking"] = true
--         BeginAcceleration:Fire()
--     elseif Humanoid.MoveDirection.Magnitude <=0 and MovementStates["Walking"] and not MovementStates["Sliding"] then
--         MovementStates["Walking"] = false
--         SprintAnim:Stop()

--         Humanoid.WalkSpeed = 8
--         CurrentSpeed = 8
--         if Connections["Accleration"] then
--             Connections["Accleration"]:Disconnect()
--             Connections["Accleration"] = nil
--         end
--         if TopSpeed then
--             local RevertZoom = TweenService:Create(Camera, TweenInfo.new(.4), {FieldOfView = 70})
--             RevertZoom:Play()
--             RevertZoom:Destroy()
--         end
--     end 
-- end)



function StartSliding(SlideLifeTime)
	--*  Old Slide loop
    --~local num = 0

	--~ while math.abs(num - 10) > 0.01 do
	--~ 	num = Util:Lerp(num, 10, 0.2)
	--~ 	local rec = num / 10
	--~ 	HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -rec)
	-- ~	RunService.RenderStepped:Wait()
	-- ~end

    Connections["SlidePromise"] = Promise.new(function(resolve, reject, onCancel)
        local elaspedTime = 0
        local StudsRate = .9
        local lifeTime = SlideLifeTime or 0.8

        Connections["Slide"] = RunService.RenderStepped:Connect(function(deltaTime)
            --elaspedTime += deltaTime
            local decelerationFactor = (elaspedTime*StudsRate) 
            local x = (StudsRate - decelerationFactor)
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -x) 
        end)

        -- onCancel(function()
        --     Connections["Slide"]:Disconnect()
        --     Connections["Slide"] = nil
        -- end)
    
        task.wait(lifeTime) 
        resolve()
    end):finally(function()
        if Connections["Slide"] then
            Connections["Slide"]:Disconnect()
            Connections["Slide"] = nil
            AnimationController:StopAnimation("Slide")
            if Character:GetAttribute("Sprinting") then
                AnimationController:PlayAnimation("Sprint")
            end
        end
    end)
end


UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.LeftShift then
        InputService:ToggleSprint():andThen(function(Verified)
            if Verified == true then
                local SprintAnim = AnimationController:GetAnimation("Sprint")
                SprintAnim:Play()
                while Character:GetAttribute("Sprinting") do
                    if Humanoid.MoveDirection == Vector3.new()then
                        SprintAnim:Stop()
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
    elseif input.KeyCode == Enum.KeyCode.C then
        if not Character:GetAttribute("Sliding") then
            local VerifySlide = InputService:ToggleSlide(true)
            VerifySlide:andThen(function(CanSlide, SlideLifeTime)
                if CanSlide then
                    StartSliding(SlideLifeTime)
                end
            end)
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        --InputService:ProcessClick()
        local TaggerObject = TaggerComponent:FromInstance(Character)
        if TaggerObject then
            TaggerObject:Swing()
        else
            warn("you're not a Tagger")
        end
    elseif input.KeyCode == Enum.KeyCode.Space then
        if Character:GetAttribute("Sliding")  then
            InputService:ToggleSlide(false, {CancelType = "Jump"})
            Connections["SlidePromise"]:cancel()
            local BV = Instance.new("BodyVelocity")
            BV.Name = "SlideJumpBV"
            BV.MaxForce = Vector3.new(1e5,1e5,1e5)
            BV.Parent = HumanoidRootPart
            game.Debris:AddItem(BV, 0.35)

            for i = 1, 10 do
                BV.Velocity = HumanoidRootPart.CFrame.LookVector * (60 - i*2) + Vector3.new(0,4+i*2,0)

                local origin = HumanoidRootPart.Position
                local dir = HumanoidRootPart.CFrame.LookVector.Unit * 3
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {Character}

                local result = workspace:Raycast(origin, dir, raycastParams)
                if result then
                    BV:Destroy()
                    break
                end
                RunService.RenderStepped:Wait()
            end

        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        --local Sprint = AnimationController:GetAnimation(Humanoid, "Sprint")
        --Sprint:Stop()
        InputService:ToggleSprint()
    end
end)

