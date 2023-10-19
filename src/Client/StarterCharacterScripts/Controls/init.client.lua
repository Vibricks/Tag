local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
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
local SlideModule = require(script.Sliding)

local BeginAcceleration = Signal.new()

local RoundService 
local InputService 
local AnimationController 
local TaggerComponent
local ReplicaInterfaceController
local PlayerProfileReplica
local AbilityService

Knit.OnStart():andThen(function()
    StateReader = require(ReplicatedStorage.Shared.StateReader)
    RoundService = Knit.GetService("RoundService")
    InputService = Knit.GetService("InputService")
    AnimationController = Knit.GetController("AnimationController")
    TaggerComponent =  require(StarterPlayerScripts.Components.Tagger)
    ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
    PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")
    AbilityService = Knit.GetService("AbilityService")
    InputService.CancelClimbing:Connect(function()
        ClimbModule.EndClimb()
        ClimbModule.EndLedgeGrab()
    end)
end)

local Connections = {}



UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
        SprintModule:BeginSprint(true)
    elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.ButtonB then
        SlideModule:BeginSlide()
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
        local TaggerObject = TaggerComponent:FromInstance(Character)
        if TaggerObject then
            TaggerObject:Swing()
        end
    elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonR1 then
        SlideModule:SlideCancel()
    elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonY then
        AbilityService:UseAbility()
    end
end)


UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.LeftShift  or input.KeyCode == Enum.KeyCode.ButtonL3 then
        SprintModule:EndSprint(true)
    end
end)



if UserInputService.TouchEnabled then
    local RoundUI = PlayerGui:WaitForChild("RoundUI")
    RoundUI:WaitForChild("Hotbar").Visible = false
    
    local MobileButtons = PlayerGui:WaitForChild("MobileButtons")
    MobileButtons.Enabled = true

    MobileButtons.Tag.Button.MouseButton1Click:Connect(function()
        local TaggerObject = TaggerComponent:FromInstance(Character)
        if TaggerObject then
            TaggerObject:Swing()
        end
    end)

    MobileButtons.Slide.Button.MouseButton1Click:Connect(function()
        SlideModule:BeginSlide()
    end)

    MobileButtons.Ability.Button.MouseButton1Click:Connect(function()
        InputService:UseAbility()
    end)

    local jumpButton = Player.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
	jumpButton.Activated:Connect(function()
		SlideModule:SlideCancel()
	end)

    MobileButtons.Climb.Button.MouseButton1Click:Connect(function()
        ClimbModule.detectWall(true)
    end)

    
    local UserGameSettings = UserSettings():GetService("UserGameSettings")
    UserGameSettings.RotationType = Enum.RotationType.CameraRelative

    Humanoid.AutoJumpEnabled = false
end