local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RoundService = Knit.GetService("RoundService") --* This is really only needed so we can access the current trove 
local ServerStorage = game:GetService("ServerStorage")
local TeamService = Knit.GetService("TeamService")

local ClassicTag = {}

ClassicTag.Config = {
    DURATION = 60
}

local CharacterDiedSignal = Signal.new()



function ClassicTag.SetupGamemode()
    local Map =  RoundService.CurrentTrove:Add(ServerStorage.Maps["Test Map"]:Clone())
    local SpawnPoints = Map.SpawnPoints:GetChildren()
    Map.Parent = workspace
    task.wait(1)

    --* Create the teams
    TeamService.CreateTeam("Chasers", true)
    TeamService.CreateTeam("Runners", true)

    --* Divide the ready players into runners and chasers and assign the teams
    local Participants = RoundService.Participants


     for i = 1, #Participants do
         local plr = Participants[i]
         if i == 1 then
             TeamService.AssignTeam(plr, "Chasers")
         else
             TeamService.AssignTeam(plr, "Runners")
         end
         local Character = plr.Character
         if Character then
             local rand = Random.new():NextInteger(-3, 3)
             Character:PivotTo(SpawnPoints[math.random(1, #SpawnPoints)].PrimaryPart.CFrame * CFrame.new(rand,3,rand))
         end
     end
    -- warn(TeamService.CurrentTeams)
	-- local numPlayers = #Participants
	-- local numRunners = math.ceil(numPlayers / 2)
	-- local numChasers = numPlayers - numRunners

    -- for i = 1, #RoundService.Participants do
    --     local Character = RoundService.Participants[i].Character
    --     if Character then
    --         local rand = Random.new():NextInteger(-3, 3)
    --         Character:PivotTo(SpawnPoints[math.random(1, #SpawnPoints)].PrimaryPart.CFrame * CFrame.new(rand,3,rand))
    --         if i <= numRunners then
    --             TeamService.AssignTeam(Participants[i], "Runners")

    --         else
    --             TeamService.AssignTeam(Participants[i], "Chasers")

    --         end
    --     end
    -- end
    task.wait(2)
end

function ClassicTag.ProcessTagHit(Attacker, Victim)
    print(Attacker, "Tagged", Victim)
    if CollectionService:HasTag(Attacker, "Chasers") then
        warn("gonna kill this man!")
        local VictimHum = Victim.Humanoid
        VictimHum:TakeDamage(VictimHum.MaxHealth)
        CharacterDiedSignal:Fire(Victim)
    end
end

function ClassicTag.StartGamemode()
end

function ClassicTag.WinCondition()
    return Promise.race({
        Promise.fromEvent(CharacterDiedSignal, function(Character)
            if CollectionService:HasTag(Character, "Runners") then
                TeamService.RemoveCharacterFromTeam(Character, "Runners")
                local TeamMembers = TeamService.CurrentTeams.Runners.Players
                local remaining = 0
                for plrIndex, dictInfo in pairs(TeamMembers) do
                    print(plrIndex, "Team member")
                    remaining += 1
                end
                if remaining == 0 then
                    return true
                end
            end
            return false
        end):andThenReturn("Win Condition Met", {})
    })
end

return ClassicTag