local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)

local Util = require(ReplicatedStorage.Shared.Util)
local MagnitudeHitbox = require(ReplicatedStorage.Shared.Hitboxes.MagnitudeHitbox)
local StateReader = require(ReplicatedStorage.Shared.StateReader)

local SFX = SoundService.SFX

local InputService 
local WeaponService
Knit.OnStart():andThen(function()
    InputService = Knit.GetService("InputService")
    WeaponService = Knit.GetService("WeaponService")
end)

local OnlyThisClient = {}



local module = Component.new({
    Tag = "Taggers",
    Extensions =  {OnlyThisClient}

})





function module:Construct()
end

function module:Start()
    local Player = game.Players:GetPlayerFromCharacter(self.Instance)
    WeaponService:EquipWeapon(Player)

end

function module:Stop()
end

function module:HeartbeatUpdate(dt)
end

function module:SteppedUpdate(dt)
end

function module:RenderSteppedUpdate(dt)
end

return module