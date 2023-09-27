local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local TeamService = Knit.CreateService {
    Name = "TeamService",
    Client = {},
}

local RoundService 

TeamService.DefaultTeamColors = {
    Chasers = Color3.fromRGB(197, 60, 60),
    Runners = Color3.fromRGB(34, 133, 255),
}

TeamService.CurrentTeams = {}

function TeamService.CreateTeam(TeamName, CanTag, Color)
    local newTeam = {}
    newTeam.Players = {}
    newTeam.CanTag = CanTag or false
    newTeam.Color = TeamService.DefaultTeamColors[TeamName] or Color
    TeamService.CurrentTeams[TeamName] = newTeam
    RoundService.CurrentTrove:Add(function()
        TeamService.CurrentTeams[TeamName] = nil
    end)
end

function TeamService.AssignTeam(Player, TeamName)
    local Team = TeamService.CurrentTeams[TeamName]
   if Team then
        warn("assigning", Player, "to", TeamName)
        Team.Players[Player] = {
            Alive = true
        }
        Player:SetAttribute("Team", TeamName)
        Player:SetAttribute("CanTag", Team.CanTag)
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local Highlight = RoundService.CurrentTrove:Add(Instance.new("Highlight"))
        Highlight.FillTransparency = 1
        Highlight.OutlineTransparency = 0
        Highlight.OutlineColor = Team.Color
        Highlight.Parent = Character
        CollectionService:AddTag(Character, TeamName)
        RoundService.CurrentTrove:Add(function()
            if CollectionService:HasTag(Character, TeamName) then
                CollectionService:RemoveTag(Character, TeamName)
            end
        end)

    end
end

function TeamService.RemoveCharacterFromTeam(Character, TeamName)
    local Player = game.Players:GetPlayerFromCharacter(Character)
    local Team = TeamService.CurrentTeams[TeamName]
    if Player and Team and Team.Players[Player] then
        Team.Players[Player] = nil
    else
        warn("Unable to remove character from team", Character.Name, TeamName, Player)
    end
end

function TeamService.ClearCurrentTeams()

end


function TeamService:KnitStart()
    
end


function TeamService:KnitInit()
    RoundService = Knit.GetService("RoundService")
end


return TeamService
