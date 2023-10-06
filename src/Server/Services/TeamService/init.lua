local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local TeamService = Knit.CreateService {
    Name = "TeamService",
    Client = {},
}

local RoundService 

TeamService.DefaultTeamColors = {
    Taggers = Color3.fromRGB(197, 60, 60),
    Runners = Color3.fromRGB(34, 133, 255),
}

TeamService.CurrentTeams = {}

function TeamService.CreateTeam(TeamName, CanTag, Color)
    local newTeam = {}
    newTeam.Name = TeamName
    newTeam.Members = {}
    newTeam.CanTag = CanTag or false
    newTeam.Color = TeamService.DefaultTeamColors[TeamName] or Color
    TeamService.CurrentTeams[TeamName] = newTeam
    RoundService.CurrentTrove:Add(function()
        TeamService.CurrentTeams[TeamName] = nil
    end)
end

function TeamService.AssignTeam(Player, TeamName)
    local Team = TeamService.CurrentTeams[TeamName]
   if Team and Player then
        Team.Members[Player] = {
            Alive = true
        }
        Player:SetAttribute("Team", TeamName)
        local Character = Player.Character
        if Character then
            local TeamOverhead = RoundService.CurrentTrove:Add(ReplicatedStorage.Assets.Misc.TeamOverhead:Clone())
            TeamOverhead.ImageLabel.ImageColor3 = Team.Color
            TeamOverhead.Parent = Character.Head
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
end

function TeamService.RemovePlayerFromTeam(Player, TeamName)
    if not TeamName then
        local Team = TeamService:GetPlayerTeam(Player)
        if Team then 
            TeamName = Team.Name
        else 
            warn(Player.Name, "Isn't on a team")
            return "NoTeam"
        end
    end
    local Team = TeamService.CurrentTeams[TeamName]
    if Player and Team and Team.Members[Player] then
        Team.Members[Player] = nil
    else
        warn("Unable to remove character from team", Player.Name, TeamName)
    end
end

function TeamService:GetPlayerTeam(Player)
    for _, Team in pairs(TeamService.CurrentTeams) do
        local TeamMembers = Team.Members
        for member, _ in pairs(TeamMembers) do
            if member.Name == Player.Name then
                warn(Player.Name, "Is Member of Team", Team.Name)

                return Team
            else
                warn(member, typeof(member))
            end
        end
    end  
end

function TeamService:IsTeamEmpty(TeamName)
    local Team = self.CurrentTeams[TeamName]
    local totalMembers = 0
    for i, v in pairs(Team.Members) do
        totalMembers += 1
    end
    if totalMembers <= 0 then
        return true
    end
    return false
end

function TeamService:GetNumOfMembersOnTeam(TeamName)
    local Team = TeamService.CurrentTeams[TeamName]
    if Team then
        local num = 0
        for i, v in pairs(Team.Members) do
            num += 1
        end
        return num
    else
        warn("team not found-", TeamName)
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
