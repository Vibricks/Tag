
--! THE RAGDOLL SYSTEM WON'T WORK UNLESS THE PHYSICS STATE IS SET ON THE CLIENT

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local StateReader = require(ReplicatedStorage.Shared.StateReader)

local Player = game.Players.LocalPlayer


Knit.OnStart():andThen(function()
	local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
	local Replica = ReplicaInterfaceController:GetReplica("StateProfile")

	Replica:ListenToChange({"Ragdolled", "StartTime"}, function(OldValue, NewValue)
		local currentCharacter = Player.Character
		if not currentCharacter then return end
		while StateReader:IsStateEnabled(currentCharacter, "Ragdolled") do
			if currentCharacter.Humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
				currentCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			end
			RunService.RenderStepped:Wait()
		end
		currentCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
end)

