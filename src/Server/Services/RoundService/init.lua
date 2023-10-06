local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Util = require(ReplicatedStorage.Shared.Util)
local RoundUtil 

local TeamService
local InputService
local StateManagerService
local PlayerDataService

local GameInfo = ReplicatedStorage.GameInfo

local INTERMISSION_DURATION = RunService:IsStudio() and 5 or 20
local REQUIRED_PLAYERS = RunService:IsStudio() and 1 or 2

local StartGameSignal = Signal.new()


local RoundService = Knit.CreateService({
	Name = "RoundService",
	Client = {
		Test = Knit.CreateSignal(),
		GameOver = Knit.CreateSignal(),
		ReflectOnUI = Knit.CreateSignal(),
	},
})

RoundService.Signals = {
	ProcessTagHit = Signal.new(),
	TimeUpSignal = Signal.new(),
	PlayerDied = Signal.new(),
	EndTimer = Signal.new()
}


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

function RoundService.EnableRoundUI()
	RoundService.Client.ReflectOnUI:FireExcept(function(plr)
		return table.find(RoundService.Participants, plr) and true
	end, "EnableRoundUI")
end

function enoughPlayers()
	return #Players:GetPlayers() >= REQUIRED_PLAYERS
end

function NotEnoughPlrsOnDeduction()
	local function EvaluateDeduction(Player, OldCharacter) --! Ends the game if the player was needed
		--*Remove them from the games participants
		local index = table.find(RoundService.Participants, Player)
		table.remove(RoundService.Participants, index)

		--local Character = Player.Character
		task.wait(2)
		local TeamIsEmpty = false

		--*Get which team they were on and remove them
		local Team = TeamService:GetPlayerTeam(Player)
		if Team then
			local TeamName = Team.Name
			TeamService.RemovePlayerFromTeam(Player, TeamName)
			TeamIsEmpty = TeamService:IsTeamEmpty(TeamName)
		end


		--* Let's see if we have enough players
		local EnoughPlayers = #RoundService.Participants >= REQUIRED_PLAYERS

		if TeamIsEmpty or not EnoughPlayers then 
			return true
		end
		return false
	end
	return Promise.race({
		Promise.fromEvent(Players.PlayerRemoving, function(Player)
			return EvaluateDeduction(Player)
		end),
		Promise.fromEvent(RoundService.Signals.PlayerDied, function(Player, OldCharacter)
			return EvaluateDeduction(Player, OldCharacter)
		end),
	}):andThenReturn("Not Enough Players")
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
			RoundService.CurrentTrove:Add(function()
				for i, v in pairs(RoundService.Participants) do
					v:SetAttribute("ForceMouseLock", false)
				end
			end)
			RoundUtil.ChangeServerMessage("Setting up the gamemode...")
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
						plr:SetAttribute("ForceMouseLock", true)

						RoundService.CurrentTrove:Add(Humanoid.Died:Connect(function()
							RoundService.Signals.PlayerDied:Fire(plr, Character)
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
				RoundUtil.ChangeServerMessage("An error occured, Set up failed, restarting game...", Color3.fromRGB(200, 51, 51))

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
	workspace.RoundMusic:Stop()
	if RoundService.CurrentTrove then
		RoundService.CurrentTrove:Destroy()
		RoundService.CurrentTrove = nil
	end
	for _, plr in pairs(RoundService.Participants) do
		local Character = plr.Character
		local Humanoid = Character and Character:FindFirstChild("Humanoid")
		if plr and Character and Humanoid then
			RoundUtil:ReturnToLobby(Character)
		end
	end
	RoundService.Participants = {}
	RoundUtil.ChangeServerMessage("Cleaning up...")

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
	return Promise.new(function(resolve, reject)
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
			GamemodeTimer(Duration)
			local race = Promise.race({ NotEnoughPlrsOnDeduction(), module.WinCondition() }) --* A race to end the game based on who wins first, time running out or not enough players to continue
			return race:andThen(function(...)
				RoundService.Signals.EndTimer:Fire()
				local args = { ... }
				local raceResult = args[1]
				local matchResults = args[2] or {}
				matchResults.WIN_TYPE = module.Config.WIN_TYPE
				if raceResult == "Not Enough Players" then
					if #RoundService.Participants >= 1 then
						local Team = TeamService:GetPlayerTeam(RoundService.Participants[1])
						matchResults.Winner = Team.Name
						matchResults.MVP = module.GetMVP(Team.Name)
						matchResults.TeamColor = Team.Color
					end
				end
				if matchResults.MVP then 
					local ThumbnailType = Enum.ThumbnailType.HeadShot
					local ThumbnailSize = Enum.ThumbnailSize.Size352x352
					matchResults.Thumbnail =  game.Players:GetUserThumbnailAsync(matchResults.MVP.UserId,ThumbnailType, ThumbnailSize) 
				end
				if matchResults.Winner then
					local WinningTeam = matchResults.Winner
					local TeamMembers = TeamService.CurrentTeams[WinningTeam].Members 
					for plr, _ in pairs(TeamMembers) do
						--* Increasing their wins
						task.defer(function()
							local replica = PlayerDataService:GetProfile(plr).Replica
							replica:SetValue({"Wins"}, replica.Data.Wins+1)
							plr.leaderstats.Wins.Value += 1
						end)
					end
				end 
				task.wait(3)
				RoundService.Client.GameOver:FireFilter(function(plr)
					return table.find(RoundService.Participants, plr) and true
				end, matchResults)
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
	task.defer(function()
		RoundUtil.ChangeServerMessage("Time Remaining: " .. Duration, Color3.fromRGB(255, 172, 28))
		local TimerCanceled = false
		RoundService.Signals.EndTimer:Connect(function()
			TimerCanceled = true
		end)
		for i = Duration, 0, -1 do
			if TimerCanceled then return end
			GameInfo.TimeRemaining.Value = i
			RoundUtil.ChangeServerMessage("Time Remaining: " .. i, Color3.fromRGB(255, 172, 28))
	
			task.wait(1)
		end
		if TimerCanceled then warn("Timer Canceled") end
		RoundUtil.ChangeServerMessage("Time is up!")
		RoundService.Signals.TimeUpSignal:Fire() --! The current game mode connects to this and chooses a winner
	end)
end

function Intermission()
	return Promise.race({
		--* Intermission count down
		Promise.new(function(resolve)
			GameInfo.Intermission.Value = INTERMISSION_DURATION

			for i = INTERMISSION_DURATION, 0, -1 do
				task.wait(1)
				GameInfo.Intermission.Value = i
				RoundUtil.ChangeServerMessage("Intermission: " .. i)
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
	RoundUtil.ChangeServerMessage("Waiting for players..")
	return IsEnoughPlayersOnJoin():andThenReturn(Intermission) --* Once theres enough players, start the intermission
end

function RoundService:KnitStart()
	task.wait(5)
	local nextFunction = waitForPlayers
	RoundUtil.ChangeServerMessage("Please wait...")

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
	InputService = Knit.GetService("InputService")
	StateManagerService  = Knit.GetService("StateManagerService")
	PlayerDataService = Knit.GetService("PlayerDataService")
	RoundUtil = require(script.RoundUtil)
end



return RoundService
