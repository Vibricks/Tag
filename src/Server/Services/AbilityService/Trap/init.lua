local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Util = require(ReplicatedStorage.Shared.Util)

local StateManagerService = Knit.GetService("StateManagerService")
local TeamService = Knit.GetService("TeamService")

return function (Player)
    local Character = Player.Character
    local HRP = Character.HumanoidRootPart

    local TrapPart = ReplicatedStorage.Assets.Misc.TrapPart:Clone()
    TrapPart.CFrame = HRP.CFrame * CFrame.new(0,-3,-4) * CFrame.Angles(0,0,math.rad(90))
    TrapPart.Anchored = true
    TrapPart.CanCollide = false
    TrapPart.Parent = workspace.Ignore

    local Team = TeamService:GetPlayerTeam(Player)
    TrapPart.Color = Team and Team.Color or Color3.fromRGB(114, 114, 114)


    game.Debris:AddItem(TrapPart, 5)
    local HitChars = {}
    TrapPart.Touched:Connect(function(Hit)
        local EnemyChar = Hit.Parent

        if EnemyChar and EnemyChar:FindFirstChild("Humanoid") and not HitChars[EnemyChar] and EnemyChar ~= Character then
            local EHum = EnemyChar.Humanoid
            Util:PlaySoundInPart(game.SoundService.SFX.Trap, HRP)
            HitChars[EnemyChar] = true
            StateManagerService:ChangeSpeed(EnemyChar, 0, 3, 2, {DisableJump = true, DisableAutoRotate = true})
            StateManagerService:UpdateState(EnemyChar, "Ragdolled", 3)
        end
    end)
end