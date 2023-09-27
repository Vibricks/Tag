local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Util = require(ReplicatedStorage.Shared.Util)

local GameInfo = ReplicatedStorage.GameInfo

local INTERMISSION_DURATION = 5
local REQUIRED_PLAYERS = 1--RunService:IsStudio() and 1 or 2

local StartGameSignal = Signal.new()

local RoundService = Knit.CreateService({
	Name = "RoundService",
	Client = {
		Test = Knit.CreateSignal(),
	},
})

RoundService.Signals = {
	ProcessTagHit = Signal.new(),
	PlayerDied = Signal.new(),
}

local TeamService
RoundService.CurrentTrove = nil

local GamemodeCache = {}
RoundService.Participants = {}

--* Signal Connections
StartGameSignal:Connect(function(GamemodeModule)
	GamemodeModule.StartGamemode()
end)

RoundService.Signals.ProcessTagHit:Connect(function(Attacker, Victim)
    if GameInfo.GameInProgress.Value == false then return end
	local GamemodeName = GameInfo.CurrentGamemode.Value
	local GamemodeModule = GamemodeCache[GamemodeName]
	if GamemodeModule then
		GamemodeModule.ProcessTagHit(Attacker, Victim)
	else
		warn("Gamemode module NOT FOUND: ", GamemodeName)
	end
end)

function enoughPlayers()
	return #Players:GetPlayers() >= REQUIRED_PLAYERS
end

function NotEnoughPlrsOnDeduction()
	return Promise.race({
		Promise.fromEvent(Players.PlayerRemoving, function()
			return #Players:GetPlayers() - 1 < REQUIRED_PLAYERS
		end),
		Promise.fromEvent(RoundService.Signals.PlayerDied, function(Player)
			task.wait(2)

			warn("well since", Player, "died lets remove them from participants")
			local index = table.find(RoundService.Participants, Player)
			table.remove(RoundService.Participants, index)
			return #RoundService.Participants - 1 < REQUIRED_PLAYERS
		end),
	}):andThenReturn("Not enough Players")
end

function IsEnoughPlayersOnJoin()
	--TODO test if this actually works
	return Promise.race({
		Promise.fromEvent(Players.PlayerAdded, function()
			return enoughPlayers()
		end),
		Promise.new(function(resolve)
			local x = enoughPlayers() and resolve()
		end),
	})
end

function SetupGame()
	return Promise.race({
		Promise.new(function(resolve, reject)
			RoundService.CurrentTrove = Trove.new()
			GameInfo.ServerMessage.Value = "Setting up the gamemode..."
			GameInfo.ServerMessage:SetAttribute("Color", Color3.fromRGB(255, 255, 255))
			local SelectedGamemode = GameInfo.CurrentGamemode.Value
			local module = GamemodeCache[SelectedGamemode]

			GameInfo.CurrentGamemode.Value = SelectedGamemode
			GameInfo.TimeRemaining.Value = module.Config.DURATION
			GameInfo.GameInProgress.Value = true
			workspace.RoundMusic:Play()
			for _, plr in pairs(game.Players:GetChildren()) do
				local Character = plr.Character
				local Humanoid = Character and Character.Humanoid

				if Character and Humanoid and Humanoid.Health > 0 then
					if not plr:GetAttribute("IsAFK") then
						table.insert(RoundService.Participants, plr)
						RoundService.CurrentTrove:Add(Humanoid.Died:Connect(function()
							print(plr, "died")
							RoundService.Signals.PlayerDied:Fire(plr)
						end))
					end
				end
			end
			--if #RoundService.Participants >= REQUIRED_PLAYERS then end

			RoundService.Participants = Util:RandomizeTable(RoundService.Participants)

			local success, returnedWith = Promise.try(module.SetupGamemode, RoundService.CurrentTrove):await()
			if success then
				resolve()
			else
				GameInfo.ServerMessage:SetAttribute("Color", Color3.fromRGB(200, 51, 51))
				GameInfo.ServerMessage.Value = "An error occured, Set up failed, restarting game..."
				warn("Set up failed: ", returnedWith)
				reject("Set up failed")
			end
		end):andThen(function()
			GameInfo.GameInProgress:SetAttribute("SettingUp", false)
			return StartGame
		end, CleanupGame),
		NotEnoughPlrsOnDeduction():andThenReturn(CleanupGame),
	})
end

function CleanupGame(...)
	print(...)
	workspace.RoundMusic:Stop()
	if RoundService.CurrentTrove then
		RoundService.CurrentTrove:Destroy()
		RoundService.CurrentTrove = nil
	end
	for _, plr in pairs(RoundService.Participants) do
		local Character = plr.Character
		local Humanoid = Character and Character:FindFirstChild("Humanoid")
		if plr and Character and Humanoid then
			warn("teleporting", plr, "back to lobby")
			Character:PivotTo(workspace.Lobby.SpawnLocation.CFrame * CFrame.new(0, 3, 0))
		end
	end
	RoundService.Participants = {}
	GameInfo.ServerMessage:SetAttribute("Color", Color3.fromRGB(255, 255, 255))
	GameInfo.ServerMessage.Value = "Cleaning up..."
	return Promise.new(function(resolve)
		--! Clean up and return the next function for the loop to run
		GameInfo.GameInProgress.Value = false
		GameInfo.CurrentGamemode.Value = "None"
		resolve()
	end):andThen(function()
		return enoughPlayers() and Intermission or waitForPlayers
	end)
end

function StartGame(...)
	print(...)
	return Promise.new(function(resolve, reject)
		print("Num Ready Players:", #RoundService.Participants)
		if #RoundService.Participants >= REQUIRED_PLAYERS then
			local CurrentGamemode = GameInfo.CurrentGamemode.Value
			local module = GamemodeCache[CurrentGamemode]
			local Duration = module.Config.DURATION

			StartGameSignal:Fire(module) --* This starts the gamemode outside of the promise chain
			resolve(Duration, module)
		else
			reject("Not enough players")
		end
	end)
		:andThen(function(Duration, module)
			local race = Promise.race({ GamemodeTimer(Duration), NotEnoughPlrsOnDeduction(), module.WinCondition() }) --* A race to end the game based on who wins first, time running out or not enough players to continue
			return race:andThen(function(...)
				local args = { ... }
				local raceResult = args[1]
				print(raceResult)
				if raceResult == "WinConditionMet" then
					GameInfo.ServerMessage.Value = "No more runners remain!"
					Promise.delay(2):await()
				end
			end):andThenReturn(CleanupGame)
		end)
		:catch(function(err)
            warn(err)

			if string.lower(err) == "not enough players" then
				return CleanupGame
			end
		end)
end

function GamemodeTimer(Duration)
	return Promise.new(function(resolve)
		GameInfo.ServerMessage:SetAttribute("Color", Color3.fromRGB(255, 172, 28))
		GameInfo.ServerMessage.Value = "Time Remaining: " .. Duration

		for i = Duration, 0, -1 do
			GameInfo.TimeRemaining.Value = i
			GameInfo.ServerMessage.Value = "Time Remaining: " .. i
			task.wait(1)
		end
		GameInfo.ServerMessage:SetAttribute("Color", Color3.fromRGB(255, 255, 255))
		GameInfo.ServerMessage.Value = "Time is up!"
		task.wait(2)
		resolve("Time is up!")
	end)
end

function Intermission()
	return Promise.race({
		--* Intermission count down
		Promise.new(function(resolve)
			GameInfo.Intermission.Value = INTERMISSION_DURATION
			GameInfo.ServerMessage:SetAttribute("Color", Color3.fromRGB(255, 255, 255))

			for i = INTERMISSION_DURATION, 0, -1 do
				task.wait(1)
				GameInfo.Intermission.Value = i
				GameInfo.ServerMessage.Value = "Intermission: " .. i
			end
			--* After the countdown is complete we select a game mode (it's random for now)
			--TODO implement a voting system
			local gamemodeArray = script.GameModes:GetChildren()
			local SelectedGameMode = gamemodeArray[math.random(1, #gamemodeArray)].Name
			GameInfo.CurrentGamemode.Value = SelectedGameMode

			resolve(SelectedGameMode) --* Here we return the name of the selected game mode
		end):andThenReturn(SetupGame),
		--* Detecting if we ran out of players
		NotEnoughPlrsOnDeduction() --* This will fire when a player leaves and theres no longer enough players
			:andThenReturn(waitForPlayers), --*The next block of code for the loop to run will be waiting for players
	})
end

function waitForPlayers()
	GameInfo.ServerMessage.Value = "Waiting for players.."
	GameInfo.ServerMessage:SetAttribute("Color", Color3.fromRGB(255, 255, 255))

	return IsEnoughPlayersOnJoin():andThenReturn(Intermission) --* Once theres enough players, start the intermission
end

function RoundService:KnitStart()
	task.wait(5)
	local nextFunction = waitForPlayers
	GameInfo.ServerMessage.Value = "Please wait..."
	while true do
		nextFunction = nextFunction():expect()
	end
end

function RoundService:KnitInit()
	for _, module in pairs(script.GameModes:GetChildren()) do
		if module:IsA("ModuleScript") then
			GamemodeCache[module.Name] = require(module)
		end
	end
	TeamService = Knit.GetService("TeamService")
end

return RoundService
