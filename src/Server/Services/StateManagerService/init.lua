local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Util = require(ReplicatedStorage.Shared.Util)

local StatePresets = require(script.StatePresets)

local module = Knit.CreateService({
	Name = "StateManagerService",
	Client = {},
})



module.CharacterProfiles = {}
module.Defaults = {
	WalkSpeed = 22,
	JumpPower = 50
}


function module.Initialize(Character)
	local Player = game.Players:GetPlayerFromCharacter(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	module.CharacterProfiles[Character] = {
		States = Util:DeepCopyTable(StatePresets);
		Connections = {}
	}
	
	--//Here is where we would update certain default states based on player data
	--local _ = PlayerData and ProfileManager.CreateAbilityGauges (PlayerData, GaugesFolder)
	Humanoid.WalkSpeed = module.Defaults.WalkSpeed
	Humanoid.JumpPower = module.Defaults.JumpPower
	Humanoid.Died:Connect(function()
		if module.CharacterProfiles[Character] then
			for i, v in pairs(module.CharacterProfiles[Character].Connections) do
				v:Disconnect()
			end

			module.CharacterProfiles[Character] = nil
		end
	end)
end

function module:IsStateEnabled(Character, StateName)
	local State = self:RetrieveState(Character, StateName)
	if State then
		local StateType = State.StateType
		local ToReturn
		if StateType == "Timed" then
			if os.clock() - State.StartTime >= State.Duration  then
				ToReturn = false
			else
				ToReturn = true
			end	
		elseif StateType == "Bool" then
			ToReturn = State.Bool
		end
		return ToReturn
	end
end


function module:UpdateState(Character, StateName, NewValue)
	local State = self:RetrieveState(Character, StateName)
	if State then
		local StateType = State.StateType
		if StateType == "Timed" then
			State.StartTime = os.clock()
			State.Duration = NewValue
		elseif StateType == "Bool" then
			State.Bool = NewValue
		end
	end
end

function module:RetrieveState(Character, StateName)
	if not module.CharacterProfiles[Character] then return end
	local State = module.CharacterProfiles[Character].States[StateName]
	if State then
		return State
	else
		warn(StateName, " -NOT FOUND")
	end
end

function module:KnitStart()

	for _, Player in pairs(game.Players:GetChildren()) do
		if Player and Player.Character then
			module.Initialize(Player.Character)
		end
	end
	
	game.Players.PlayerAdded:Connect(function(Player)
		Player.CharacterAdded:Connect(function(Character)
			module.Initialize(Character)
		end)
	end)
end

function module:KnitInit()
	
end

return module