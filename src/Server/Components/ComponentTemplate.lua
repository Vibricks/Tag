local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Util = require(ReplicatedStorage.Shared.Util)


local module = Component.new({
    Tag = "None",
})



function module:Construct()
end

function module:Start()
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