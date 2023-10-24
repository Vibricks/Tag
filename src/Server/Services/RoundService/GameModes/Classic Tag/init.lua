local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local StateReader = require(ReplicatedStorage.Shared.StateReader)
local Util = require(ReplicatedStorage.Shared.Util)

local RoundService = Knit.GetService("RoundService") --* This is really only needed so we can access the current trove
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local TeamService = Knit.GetService("TeamService")
local InputService = Knit.GetService("InputService")
local StateManagerService = Knit.GetService("StateManagerService")
local PlayerDataService = Knit.GetService("PlayerDataService")


local RoundUtil = require(script.Parent.Parent.RoundUtil)
local module = {}

module.Config = {
	DURATION = 90,
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
	TeamService.CreateTeam("Taggers")
	TeamService.CreateTeam("Runners")

	TeamService.CurrentTeams["Runners"].Description = "Run away from all taggers until the time runs out!"
	TeamService.CurrentTeams["Taggers"].Description = "Capture all runners before the time runs out!"

	--* Divide the ready players into runners and Taggers and assign the teams
	local Participants = RoundService.Participants

	local totalPlrs = #Participants
	local TaggerPercentage = 20 --*20% of the server will be taggers
	local totalTaggers = math.ceil(totalPlrs * TaggerPercentage / 100)
	for i = 1, #Participants do
		local plr = Participants[i]
		local Character = plr.Character
		
		local SelectedTeam
		if i <= totalTaggers then
			SelectedTeam = "Taggers"
		else
			SelectedTeam = "Runners"
		end


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

		
		--! Team Reveal
		task.defer(function()
			local RevealCountdown = 5
			RoundUtil.ChangeServerMessage("Prepare for teams to be revealed!")
			local TeamRevealName = SelectedTeam == "Taggers" and "Tagger" or SelectedTeam == "Runners" and "Runner"
			local Description = TeamService.CurrentTeams[SelectedTeam].Description
			local Color = TeamService.CurrentTeams[SelectedTeam].Color
			RoundService.Client.ReflectOnUI:Fire(plr, "TeamReveal", {"You are a", TeamRevealName, Description, Color, RevealCountdown})
			task.wait(RevealCountdown)
			TeamService.AssignTeam(plr, SelectedTeam)
		end)

	end

	RoundService.CurrentTrove:Add(function()
		module.Logger = {}
	end)

	task.wait(5) --! IMPORTANT: Wait for the reveal to finish
end


function Knockback(Attacker, Victim, KnockbackData)--TODO move this to its own module or inside util
	local AttackerHRP = Attacker:FindFirstChild("HumanoidRootPart")
	local VictimHRP = Victim:FindFirstChild("HumanoidRootPart")
	if not VictimHRP or not AttackerHRP then return end
	for i, v in pairs(VictimHRP:GetChildren()) do
		if v:IsA("BodyVelocity") then
			v:Destroy()
		end
	end
	VictimHRP.Velocity = Vector3.new()
	local dir = (VictimHRP.Position - AttackerHRP.Position).Unit
	local Speed = KnockbackData and KnockbackData.Speed or 45
	local UpVector = KnockbackData and KnockbackData.UpVector or 0.4

	local BP = Instance.new("BodyVelocity")
	BP.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	BP.Velocity = (dir + Vector3.new(0, UpVector, 0)).Unit * Speed
	BP.Parent = VictimHRP
	game.Debris:AddItem(BP, KnockbackData.LifeTime or 0.1)
end

function module.ProcessTagHit(Attacker, Victim)
	local AttackerPlr = game.Players:GetPlayerFromCharacter(Attacker)
	local VictimPlr = game.Players:GetPlayerFromCharacter(Victim)
	local AttackerRagdolled = StateReader:IsStateEnabled(Attacker, "Ragdolled")
	local VictimRagdolled = StateReader:IsStateEnabled(Victim, "Ragdolled")
	if AttackerRagdolled or VictimRagdolled then return end
	if CollectionService:HasTag(Attacker, "Taggers") and not CollectionService:HasTag(Victim, "Taggers") then
		if not VictimPlr:GetAttribute("InGame") then return end
		local VictimHum = Victim.Humanoid
		local VictimHRP = Victim.HumanoidRootPart

		if VictimHRP then 
			Util:PlaySoundInPart(SoundService.SFX.SwipeHit, VictimHRP)
		end
		
		StateManagerService:UpdateState(Victim, "Ragdolled", 10)
		
		RoundService.Client.ReflectOnUI:FireAll("TagLog", {Attacker.Name, Victim.Name})
		RoundService.Client.ReflectOnUI:Fire(VictimPlr, "YouWereTagged")

		--TeamService.CurrentTeams.Runners.Members[Victim].Alive = false
		VictimPlr:SetAttribute("InGame", false)

		--* Removing them from the match
		task.delay(1, function()
			RoundUtil:ReturnToLobby(Victim)
		end)

		--* Increasing their tags
		local replica = PlayerDataService:GetProfile(AttackerPlr).Replica
		replica:SetValue({"Tags"}, replica.Data.Tags+1)
		module.Logger[AttackerPlr].Tags = module.Logger[AttackerPlr].Tags + 1
		AttackerPlr.leaderstats.Tags.Value += 1

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
					if plrIndex:GetAttribute("InGame") then
						remaining += 1
					end
				end
				if remaining <= 0 then
					return true
				end
			end
			return false
		end):andThen(function()
			warn("Win Condition")
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
