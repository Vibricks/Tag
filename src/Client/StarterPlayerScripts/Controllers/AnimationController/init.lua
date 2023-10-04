--// cache loaded animations in humanoids and clean them up when the humanoid is destroyed
--// or streamed out. basically just an abstraction so we dont repeat the code pattern in
--// multiple files
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local AnimationService 

local Animations = ReplicatedStorage.Assets.Animations

local module = Knit.CreateController({
	Name = "AnimationController",
})

local tracks = {}

module.AnimationFunctions = {
	["Get"] = function(humanoid, animName, Properties)
		animName = animName
	
		if not tracks[humanoid] then
			tracks[humanoid] = {}
	
			--! Destroying doesnt fire for character or members of a character
			local con
			con = humanoid.AncestryChanged:Connect(function(_, newParent)
				if not newParent then
					con:Disconnect()
					con = nil
	
					module:StopAllAnimations(humanoid)
					tracks[humanoid] = nil
				end
			end)
		end
	
		local thisCache = tracks[humanoid]
		local foundTrack = thisCache[animName]
		if foundTrack then --* if we found a track already loaded
			return foundTrack 
		elseif not foundTrack then --* If no track was found then we make one 
			local animator = humanoid:FindFirstChild("Animator") or humanoid
			local animObj = Animations:FindFirstChild(animName, true)
			if animObj then
				local animationTrack = animator:LoadAnimation(animObj)
				local _ = Properties and ApplyProperties(animationTrack, Properties)
	
				thisCache[animName] = animationTrack
				return animationTrack
			else
				warn("Animation track not found: ", animName)
				return nil
			end
		end
	end,
	["Play"] = function (Humanoid, AnimName, Properties)
		local Anim = module.AnimationFunctions.Get(Humanoid, AnimName, Properties)
		Anim:Play()
		if Properties and Properties.Speed then
			Anim:AdjustSpeed(Properties.Speed)
		end
		return Anim
	end,
	

	["Stop"] = function(Humanoid, AnimName)
		local thisCache = module:GetCache(Humanoid)
		local Animation = thisCache and thisCache[AnimName]
		if Animation then
			Animation:Stop()
		end
	end

}

function ApplyProperties(Track, Properties)
	for propertyName, value in pairs(Properties) do
		--print("test:", propertyName, value)
		if propertyName == "Speed" then continue end
		Track[propertyName] = value
	end
end

function module:StopAllAnimations(humanoid)
	local cache = tracks[humanoid]
	if cache then
		for i, v in cache do
			v:Stop()
			v:Destroy()
			cache[i] = nil
		end
	end
end

function module:GetAnimation(animName, Properties)
	local char = Knit.Player.Character
	if char then
		local humanoid = char:WaitForChild("Humanoid")
		return module.AnimationFunctions.Get(humanoid, animName, Properties)
	end
end

function module:PlayAnimation(AnimName, Properties)
	local char = Knit.Player.Character
	if char then
		local humanoid = char:WaitForChild("Humanoid")
		return module.AnimationFunctions.Play(humanoid, AnimName, Properties)
	end
end

function module:StopAnimation(AnimationName) 
	local char = Knit.Player.Character
	if char then
		local humanoid = char:WaitForChild("Humanoid")
		module.AnimationFunctions.Stop(humanoid, AnimationName)
	end
end

function module:GetCache(humanoid)
	return tracks[humanoid]
end

function module:KnitStart()
	AnimationService.StopAnimation:Connect(module.AnimationFunctions.Stop)
	
	AnimationService.PlayAnimation:Connect(module.AnimationFunctions.Play)
end

function module:KnitInit()
	AnimationService = Knit.GetService("AnimationService")
end

return module