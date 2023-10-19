local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

Knit.OnStart():await()

local InputService = Knit.GetService("InputService")
local UserInputService = game:GetService("UserInputService")
local AnimationController = Knit.GetController("AnimationController")
local StateReader = require(ReplicatedStorage.Shared.StateReader)
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")

local module = {}
local Connections = {}

function StartSliding(SlideLifeTime)
    for i, v in pairs(HumanoidRootPart:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
            v:Destroy()
        end
    end

    local BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(1e5,0,1e5)
    BV.Name = "SlideBV"
    BV.Parent = HumanoidRootPart

    Connections["SlidePromise"] = Promise.new(function(resolve, reject, onCancel)
        local startTime = tick()
        local StudsRate = 60
        local lifeTime = SlideLifeTime or 0.8

        Connections["Slide"] = RunService.RenderStepped:Connect(function(deltaTime)
            local elaspedTime = tick() - startTime
            local decelerationFactor = (elaspedTime*StudsRate)/10
            local x = (StudsRate - decelerationFactor)
            BV.Velocity = HumanoidRootPart.CFrame.LookVector *x

            local origin = HumanoidRootPart.Position + Vector3.new(0,-2,0)
            local dir = HumanoidRootPart.CFrame.LookVector.Unit * 3
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {Character}

            local result = workspace:Raycast(origin, dir, raycastParams)
            local Instance = result and result.Instance
            if Instance then
                if Instance.Anchored == true and Instance.CanCollide == true and  (Instance.Parent.Name ~= "Vault" and Instance.Parent.Parent.Name ~= "Vault") then
                    InputService:ToggleSlide(false)
                    resolve()
                end
            end
        end)
    
        task.wait(lifeTime) 
        resolve()
    end):finally(function()
        if Connections["Slide"] then
            BV:Destroy()
            Connections["Slide"]:Disconnect()
            Connections["Slide"] = nil
            AnimationController:StopAnimation("Slide")
            if Character:GetAttribute("Sprinting") then
                AnimationController:PlayAnimation("Sprint")
            end
        end
    end)
end

function module:SlideCancel()
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


function module:BeginSlide()
    if not Character:GetAttribute("Sliding") then
        local VerifySlide = InputService:ToggleSlide(true)
        VerifySlide:andThen(function(CanSlide, SlideLifeTime)
            if CanSlide then
   
                StartSliding(SlideLifeTime)
            end
        end)
    end
end




return module