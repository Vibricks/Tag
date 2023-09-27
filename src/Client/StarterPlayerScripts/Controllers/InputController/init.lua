local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Player = Knit.Player

local InputController = Knit.CreateController { Name = "InputController" }


function InputController:KnitStart()
    InputService.InputBegan:Connect(function(input, gameProcessedEvent)
        
    end)
end


function InputController:KnitInit()
    
end


return InputController
