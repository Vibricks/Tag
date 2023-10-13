local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Util = require(ReplicatedStorage.Shared.Util)

local StatService = Knit.CreateService {
    Name = "StatService",
    Client = {},
}

local PlayerDataService

local function LevelUp(Player)
    local Profile = PlayerDataService:GetProfile(Player)
    local Level = Profile.Replica.Data.Level
    local StatPoints = Profile.Replica.Data.StatPoints
    Profile.Replica:SetValue({"Level"}, Level + 1)
    Profile.Replica:SetValue("StatPoints", StatPoints+2)
    Profile.Replica:SetValue({"Exp"}, 0)
end

function StatService:IncreaseExp(Player, Amount)
    local Profile = PlayerDataService:GetProfile(Player)
    local Level = Profile.Replica.Data.Level
    local CurrentExp = Profile.Replica.Data.Exp
    local MaxExp = Util:CalculateMaxExp(Level)
    local NewExp = CurrentExp + Amount

    Profile.Replica:SetValue({"Exp"}, math.clamp(NewExp, 0, MaxExp))
    if NewExp == MaxExp then --! Level up if they hit the max exp
        LevelUp(Player)
    elseif NewExp > MaxExp then--! Level up AND give them the remaining exp if they go over the limit
        LevelUp(Player)
        self:IncreaseExp(Player, NewExp - MaxExp)
    end
end


function StatService:IncreaseCash(Player, Amount)
    local Profile = PlayerDataService:GetProfile(Player)
    Profile.Replica:SetValue({"Cash"}, Profile.Replica.Data.Cash + Amount)
end

function StatService.Client:ChangeSetting(Player, SettingName, NewSetting)
    local Profile = PlayerDataService:GetProfile(Player)

    if SettingName == "AutoSprint" and type(NewSetting) == "boolean" then
        Profile.Replica:SetValue({"Settings", "AutoSprint"}, NewSetting)
    end

    if SettingName == "BackgroundMusic" and type(NewSetting) == "boolean" then
        Profile.Replica:SetValue({"Settings", "Audio", "BackgroundMusic"}, NewSetting)

    end
end


function StatService:KnitStart()
    
end


function StatService:KnitInit()
    PlayerDataService = Knit.GetService("PlayerDataService")
end


return StatService
