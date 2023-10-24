local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ReplicaService = require(ReplicatedStorage.Packages.ReplicaService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ProfileService = require(script.ProfileService)

local module = Knit.CreateService({
	Name = "PlayerDataService",
})

local PlayerProfile = {}
PlayerProfile.__index = PlayerProfile
local profileCache = {} -- [player] = {Profile = profile, Replica = replica}

local IS_STUDIO = game:GetService("RunService"):IsStudio()
local FORCE_USER_ID = 0 --// in case you want to force load somebody else's data
local DATASTORE_VERSION = 6.93

local defaultPlayerData = {
	Level = 1,
	Exp = 0,
	StatPoints = 0,
    Wins = 0,
	Coins = 0,
    Tags = 0,

	Settings = {
		AutoSprint = false,
		Audio = {
			BackgroundMusic = true,
			SFX = true,
		},
	},

    Inventory = {
		CurrentTitle = "Rich",
		CurrentAbility = "Trap",
		CurrentWeapon = "None",
        TagWeapons = {},
		Abilities = {},--["Invisibility"] = {Upgrades = 1}},
		Titles = {},
    },


    Perks = {
        Tagger = {},
        Runner = {},
    }
}

local gameProfileStore = ProfileService.GetProfileStore(
	"PlayerData"..DATASTORE_VERSION,
	defaultPlayerData
)

local playerProfileClassToken = ReplicaService.NewClassToken("PlayerProfile")

local function connectLeaderstats(ProfileStore)
	local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    
    local Wins = Instance.new("NumberValue")
    Wins.Name = "Wins"
    Wins.Value = ProfileStore.Profile.Data.Wins

    Wins.Parent = leaderstats

    local Tags = Instance.new("NumberValue")
    Tags.Name = "Tags"
	Tags.Value = ProfileStore.Profile.Data.Tags
    Tags.Parent = leaderstats

	leaderstats.Parent = ProfileStore._player

end

local function playerAdded(player)
	local userId = player.UserId
	if FORCE_USER_ID and FORCE_USER_ID > 0 and IS_STUDIO then
		userId = FORCE_USER_ID
	end
	if player.UserId < 1 then --// test server creates accounts with negative user ids
		userId = math.random(1, 500)
        print(userId)
	end
	
	local profile = gameProfileStore:LoadProfileAsync("player_" .. userId, "ForceLoad")
	if profile ~= nil then
		profile:AddUserId(userId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			local cachedProfile = profileCache[player]
			if cachedProfile then
				----// destroy all player replicas! im doing it like this because i had a game where i had several diff replicas inside the player profile
				for _, v in {"Replica"} do
					if cachedProfile[v] then
						cachedProfile[v]:Destroy()
					end
				end
			end
			profileCache[player] = nil
		end)
		
		if player:IsDescendantOf(game.Players) == true then --// profile successfully loaded
			local player_profile = {
				_player = player,
				Profile = profile,
				Replica = ReplicaService.NewReplica({
					ClassToken = playerProfileClassToken,
					Tags = {Player = player},
					Data = profile.Data,
					Replication = player,
				}),
			}
			
			setmetatable(player_profile, PlayerProfile)
			profileCache[player] = player_profile
			
			connectLeaderstats(player_profile)

		else
			print(string.format("%s left while their profile was being loaded", player.Name))
			profile:Release()
		end
	else
		print(string.format("Failed to ForceLoad %s's profile", player.Name))
		player:Kick("Sorry, another server in this game may be trying to load your profile at the same time! Wait a minute and rejoin.") 
	end
end


local function playerRemoved(player)
	local playerProfile = profileCache[player]
	if playerProfile then
		playerProfile.Profile:Release()
	end
end


function module:GetProfile(player, disableYield, timeout)
	local success, Data = Promise.new(function(resolve, reject)
        if not player then
            reject(nil, warn(string.format("PlayerDataService:GetProfile expected Player, got %s\n%s", tostring(player), debug.traceback())))
        end

        if not disableYield and not profileCache[player] then
            timeout = timeout or 10
            local t = os.clock()
            while not profileCache[player] do
                if os.clock() - t >= timeout then
                    if player.Parent then --// maybe someone left while their profile was loading. we don't want a bunch of infnite yield warnings from that
                        local errorMsg = "Infinite yield possible on " .. player.Name .. "'s Profile"
                        warn(errorMsg)
                        reject(errorMsg)
                    end
                end
                task.wait(.1)
                t = t + os.clock()
            end
        end
        resolve(profileCache[player])
    end):await()
    return Data
end


function PlayerProfile:IsActive()
	return profileCache[self._player] ~= nil
end

function module:KnitInit()
	
end

function module:KnitStart()
	for _, player in game.Players:GetPlayers() do
		task.defer(playerAdded, player)
	end
	game.Players.PlayerAdded:Connect(playerAdded)

	game.Players.PlayerRemoving:Connect(function(player)
		playerRemoved(player)
	end)
	
	game:BindToClose(function()
		for _, player in pairs(game.Players:GetPlayers()) do
			playerRemoved(player)
		end
	end)
end

return module