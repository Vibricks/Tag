local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RoundService = Knit.GetService("RoundService") --* This is really only needed so we can access the current trove
local ServerStorage = game:GetService("ServerStorage")
local TeamService = Knit.GetService("TeamService")
local InputService = Knit.GetService("InputService")

local RoundUtil = require(script.Parent.Parent.RoundUtil)
local module = {}

module.Config = {
	DURATION = 10,
	WIN_TYPE = "ONE_MVP",
}

module.Logger = {}

local CharacterTaggedSignal = Signal.new()

function module.SetupGamemode()
	local Map = RoundService.CurrentTrove:Add(ServerStorage.Maps["Test Map"]:Clone())
	local SpawnPoints = Map.SpawnPoints:GetChildren()
	Map.Parent = workspace
	task.wait(1)

	--* Create the teams
	TeamService.CreateTeam("Taggers", true)
	TeamService.CreateTeam("Runners", true)

	--* Divide the ready players into runners and Taggers and assign the teams
	local Participants = RoundService.Participants

	for i = 1, #Participants do
		local plr = Participants[i]
		local Character = plr.Character

		local SelectedTeam
		--TODO make the ammount of taggers scale with the server size
		if i == 1 then
			SelectedTeam = "Taggers"
		else
			SelectedTeam = "Runners"
		end

		TeamService.AssignTeam(plr, SelectedTeam)
		--! Logger is important for keeping track of what happens in during the match
		module.Logger[plr] = {
			Team = SelectedTeam,
		}
		if SelectedTeam == "Taggers" then
			module.Logger[plr].Tags = 0
		elseif SelectedTeam == "Runners" then
			module.Logger[plr].TimeSurvived = 0
		end
		--*Teleporting the player!
		if Character then
			local rand = Random.new():NextInteger(-3, 3)
			task.defer(function()
				InputService.Client.CancelClimbing:Fire(plr)
				task.wait(0.25)
				Character:PivotTo(
					SpawnPoints[math.random(1, #SpawnPoints)].PrimaryPart.CFrame * CFrame.new(rand, 3, rand)
				)
			end)
		end
		RoundService.EnableRoundUI()
	end

	RoundService.CurrentTrove:Add(function()
		module.Logger = {}
	end)

	task.wait(2)
end

function module.ProcessTagHit(Attacker, Victim)
	local AttackerPlr = game.Players:GetPlayerFromCharacter(Attacker)
	if CollectionService:HasTag(Attacker, "Taggers") then
		RoundService.Client.ReflectOnUI:FireAll("TagLog", {Attacker.Name, Victim.Name})
		--warn("Tagging", Victim.Name)
		local VictimHum = Victim.Humanoid
		VictimHum:TakeDamage(VictimHum.MaxHealth)

		module.Logger[AttackerPlr].Tags = module.Logger[AttackerPlr].Tags + 1
		CharacterTaggedSignal:Fire(Victim)
	end
end

function module.StartGamemode() end

function module.WinCondition()
	local MatchResults = {
		Winner = nil,
		CustomWinMessage = nil,
		WIN_TYPE = module.Config.WIN_TYPE,
		MVP = nil,
		TeamColor = Color3.fromRGB(255, 255, 255)
	};

	return Promise.race({
		Promise.fromEvent(CharacterTaggedSignal, function(Character)
			if CollectionService:HasTag(Character, "Runners") then
				--TeamService.RemovePlayerFromTeam(Character, "Runners")
				local TeamMembers = TeamService.CurrentTeams.Runners.Members
				local remaining = 0
				for plrIndex, dictInfo in pairs(TeamMembers) do
					--print(plrIndex, "Is a member of Runners")
					remaining += 1
				end
				--warn("Reaming players:", remaining)
				if remaining - 1 <= 0 then
					return true
				end
			end
			return false
		end):andThen(function()
			RoundUtil.ChangeServerMessage("No more runners remain!")

			MatchResults.Winner = "Taggers"
			MatchResults.MVP = module.GetMVP("Taggers")
			MatchResults.TeamColor = TeamService.DefaultTeamColors.Taggers
			return "Win Condition Met", MatchResults
		end),
		Promise.fromEvent(RoundService.Signals.TimeUpSignal, function()
			return true
		end):andThen(function()
			RoundUtil.ChangeServerMessage("The runners survived!!")

			MatchResults.Winner = "Runners"
			MatchResults.TeamColor = TeamService.DefaultTeamColors.Runners
			MatchResults.MVP = module.GetMVP("Runners")
			return "Win Condition Met", MatchResults
		end)
	})
end

function module.GetMVP(TeamName)
	local MVP

	if TeamName == "Taggers" then
		local MostTags = 0
		for plr, loggedInfo in pairs(module.Logger) do
			if loggedInfo.Team == TeamName then
				if loggedInfo.Tags >= MostTags then
					MVP = plr
					MostTags = loggedInfo.Tags
				end
			end
		end
	elseif TeamName == "Runners" then
		local NumOfRunners = TeamService:GetNumOfMembersOnTeam("Runners")
		if NumOfRunners == 1 then
			table.foreach( TeamService.CurrentTeams.Runners.Members, function(plr, plrInfo)
				MVP = plr
			end)
		end
	end
	return MVP

end

return module
