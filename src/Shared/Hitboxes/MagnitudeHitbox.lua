
return function(HitboxInfo)
	local Character = HitboxInfo.Character
	local Position = HitboxInfo.Position or Character:GetPivot().Position
	if not Character or not Position then warn("Can't run this hitbox, character or position needed") return end
	local Range = HitboxInfo.Range or 5
	local MultipleVictims = HitboxInfo.MultipleVictims or false
	
	local parts = workspace:GetPartBoundsInRadius(Position , Range)
	local HitResults = false
	local nearestDistance = math.huge
	local nearestEnemy = nil
	local Victims = {}
	for i, v in pairs(parts) do
		local enemyChar = v.Parent
		local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
		local enemyHRP = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")

		if enemyHum and enemyHRP and enemyChar ~=  Character and not Victims[enemyChar] and enemyHum.Health > 0 then			
			local distance = (Position - enemyHRP.Position).magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestEnemy = enemyChar
			end
			HitResults = true
			Victims[enemyChar] = distance
		end
	end
	if not MultipleVictims then Victims = nearestEnemy end
	return HitResults, Victims
end