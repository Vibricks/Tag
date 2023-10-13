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
local StateReader 

local ClimbModule = require(script.Climbing)
local VaultingModule = require(script.Vaulting)
local SprintModule = require(script.Sprinting)

local BeginAcceleration = Signal.new()

local RoundService 
local InputService 
local AnimationController 
local TaggerComponent
local ReplicaInterfaceController
local PlayerProfileReplica

Knit.OnStart():andThen(function()
    StateReader = require(ReplicatedStorage.Shared.StateReader)
    RoundService = Knit.GetService("RoundService")
    InputService = Knit.GetService("InputService")
    AnimationController = Knit.GetController("AnimationController")
    TaggerComponent =  require(StarterPlayerScripts.Components.Tagger)
    ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
    PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")
    InputService.CancelClimbing:Connect(function()
        ClimbModule.EndClimb()
        ClimbModule.EndLedgeGrab()
    end)
end)

local Connections = {}





function StartSliding(SlideLifeTime)
    Connections["SlidePromise"] = Promise.new(function(resolve, reject, onCancel)
        local elaspedTime = 0
        local StudsRate = .9
        local lifeTime = SlideLifeTime or 0.8

        Connections["Slide"] = RunService.RenderStepped:Connect(function(deltaTime)
            local decelerationFactor = (elaspedTime*StudsRate) 
            local x = (StudsRate - decelerationFactor)
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -x) 
        end)
    
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
        SprintModule:BeginSprint(true)
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
    elseif input.KeyCode == Enum.KeyCode.E then
        InputService:UseAbility()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        --local Sprint = AnimationController:GetAnimation(Humanoid, "Sprint")
        --Sprint:Stop()
        SprintModule:EndSprint(true)

    end
end)

