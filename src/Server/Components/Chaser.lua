local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Util = require(ReplicatedStorage.Shared.Util)
local ClientCast = require(ServerScriptService.Modules.ClientCast)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local RoundService 

--Knit.OnStart():andThen(function()
--end)

local SwingFinishedEvent = Signal.new()
local module = Component.new({
    Tag = "Chasers",
})

function module:ToggleHitDetection(Bool)
    if not self.ClientCaster then return end

    if Bool == true then
        self.ClientCaster:Start()
        self.Swinging = true
    else
        SwingFinishedEvent:Fire()
        self.ClientCaster:Stop()
        self.Swinging = false
    end
end

local function CreateHitbox(Character)
    local Hand = Character:FindFirstChild("RightHand")

    local Hitbox = Instance.new("Part")
    Hitbox.Size = Vector3.new(2,2,2)
    Hitbox.Transparency = 1
    Hitbox.CFrame = Hand.CFrame
    Hitbox.Massless = true
    Hitbox.CanCollide = false

    local Weld = Instance.new("WeldConstraint")
    Weld.Part0 = Hand
    Weld.Part1 = Hitbox
    Weld.Parent = Hitbox

    Hitbox.Parent = Character
    Util:CoverPartInAttachments(Hitbox, "DmgPoint")
    return Hitbox
end

function module:Construct()
    RoundService = Knit.GetService("RoundService")
    local Character = self.Instance
    local Player = game.Players:GetPlayerFromCharacter(Character)

    local Hitbox = CreateHitbox(Character)
    self._trove = Trove.new()
    self.Player = Player
    self.Hitbox = Hitbox
    self.ClientCaster = ClientCast.new(Hitbox, RaycastParams.new())

    self._trove:Add(Hitbox)
end



function module:Start()
    local ClientCaster = self.ClientCaster
    local Debounce = {}
    local _ = self.Player and ClientCaster:SetOwner(self.Player)
    ClientCaster.HumanoidCollided:Connect(function(RaycastResult, HitHumanoid)
        if Debounce[HitHumanoid] or  HitHumanoid == self.Instance.Humanoid then return end
        Debounce[HitHumanoid] = true
        RoundService.Signals.ProcessTagHit:Fire(self.Instance, HitHumanoid.Parent) --! Attacker, Victim
        --HitHumanoid:TakeDamage(HitHumanoid.MaxHealth)
    end)
    --ClientCaster._Debug = true
    self.ClientCaster = ClientCaster
end

function module:Stop()

    if self.Swinging == true then
        print("we're swinging, lets wait for it to stop")
        SwingFinishedEvent:Once(function()
            self._trove:Destroy()
        end)
    else
        print("okay we're not swinging, lets destroy clientcaster")
        self._trove:Destroy()
    end
end

function module:HeartbeatUpdate(dt)
end

function module:SteppedUpdate(dt)
end

function module:RenderSteppedUpdate(dt)
end

return module