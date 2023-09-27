local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Util = require(ReplicatedStorage.Shared.Util)

local Animations = ReplicatedStorage.Assets:WaitForChild("Animations")

local module = Knit.CreateService({
	Name = "AnimationService",
	Client = {
		PlayAnimation = Knit.CreateSignal();
		StopAnimation = Knit.CreateSignal();
	},

})

local CachedAnims = {}

function module:PlayAnimation(Humanoid, AnimName, Properties)
	local Character = Humanoid.Parent
	local Player = Character and game.Players:GetPlayerFromCharacter(Character)
	
	local anim = CachedAnims[AnimName]
	if not anim then warn(AnimName, "NOT FOUND") return end
	if Player then
		module.Client.PlayAnimation:Fire(Player, Humanoid, AnimName, Properties)
	else
		local Animator = Humanoid:FindFirstChild("Animator")
		local AnimTrack = Animator and Animator:LoadAnimation(anim) or Humanoid:LoadAnimation(anim)
		if Properties then
			for propertyName, value in pairs(Properties) do
				if propertyName == "Speed" then continue end
				--warn(AnimTrack[propertyName]) --//Prints the property's current state
				AnimTrack[propertyName] = value --//Doesn't change the state
				--warn(AnimTrack[propertyName]) --//Prints the same exact thing as before
			end
		end
		AnimTrack:Play()
		if Properties.Speed then AnimTrack:AdjustSpeed(Properties.Speed) end
		return AnimTrack
	end
end

function module:StopAnimation(Humanoid, AnimName)
	local Character = Humanoid.Parent
	local Player = Character and game.Players:GetPlayerFromCharacter(Character)

	local anim = CachedAnims[AnimName]
	if not anim then warn(AnimName, "NOT FOUND") return end
	if Player then
		module.Client.StopAnimation:Fire(Player, Humanoid, AnimName)
	else
		local playingTracks = Character.Humanoid.Animator:GetPlayingAnimationTracks()
		for _, track in playingTracks do
			if track.Name == AnimName then
				track:Stop()
			end
		end
	end
end

function module:KnitStart()
	local existingAnims = Util:deepSearchFolder(Animations, "Animation")
	for _, Animation in pairs(existingAnims) do
		CachedAnims[Animation.Name] = Animation
	end
end

function module:KnitInit()
	
end

return module