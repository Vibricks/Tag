local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage.Shared.Util)
local Knit = require(ReplicatedStorage.Packages.Knit)

local StateManagerService = Knit.GetService("StateManagerService")

local SFX = game:GetService("SoundService").SFX

return function (Player)
    local Character = Player.Character
    local HRP = Character.HumanoidRootPart
    Util:SetCharacterVisibility(Character, false)
    Util:PlaySoundInPart(SFX.Poof, HRP)
    task.wait(3)
    Util:SetCharacterVisibility(Character, true)
end