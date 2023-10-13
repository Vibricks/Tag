local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local module = {}

function module:RandomizeTable(tbl)
	local returntbl={}
	if tbl[1]~=nil then
		for i=1,#tbl do
			table.insert(returntbl,math.random(1,#returntbl+1),tbl[i])
		end
	end
	return returntbl
end



function module:GetCore(str)
	local result
	local success = false
	while not success do
		success = pcall(function()
			result = game.StarterGui:GetCore(str)
		end)
		task.wait(0.1)
	end
	return result
end

function module:LuckMultiplierAsymptote(x)
	return 	-1 * math.pow(x + 1, -1) + 1
end

function module:SafeApiCallWithTimeout(func, timeout, name)
	timeout = timeout or 60
	name = name or "N/A"
	local started = tick()
	while true do
		local success, result = pcall(function()
			return func()
		end)
		if success then
			return success, result
		elseif tick() - started >= timeout then
			return false, warn(("API call %s failed after %d seconds because %s"):format(name, timeout, result))
		end
		task.wait(1)
	end
end

	
function module:AddCommas(n, decimals)
	local abs = math.abs(n)
	local pre = math.floor(abs)
	local post = abs%1
	local s = ("%d"):format(pre)

	for i=1, (#s-1)/3 do
		local anchor = -(3*i + (i-1))
		s = s:sub(1, anchor-1)..','..s:sub(anchor)
	end

	if n < 0 then
		s = '-'..s
	end

	if post ~= 0 then
		decimals = decimals or 0
		decimals = math.clamp(decimals, 0, 10)
		local postTxt = math.floor(post * 10^decimals)
		s = ('%s.%d'):format(s, postTxt)
	end

	return s
end

local abs = {'k','m','b','t','qd','qn','sx','sp','o','n','de','ud','dd', 'td', 'qtd', 'qnd', 'sxd', 'spd', 'od', 'nd', 'vg'}
function module:AbbreviateNum(n)
	if n < 1000 then return n end
	if n == "0" or n == 0 then return 0 end

	local numb = math.abs(tonumber(n))
	local i = math.min(math.floor(math.log10(numb) / 3), #abs)
	local suffix = tonumber(i) > 0 and abs[i] or ''
	local num = tostring(numb / 10 ^ (3 * i))
	local format = num:match("%d+.%d%d") --// the extra %d on the end makes it 1.25m instead of 1.2m
	format = format or num

	local str = format .. suffix
	if n < 0 then
		str = "-" .. str
	end

	if str:sub(#str - 1, #str) == ".0" then --// remove ".0" from "46.0"
		str = str:sub(1, #str - 2)
	end

	return str
end

function module:TweenModelCFrame(model, targetCF, tweenInfo, onComplete)
	local cfValue = Instance.new("CFrameValue")

	local function onChanged(value)
		model:PivotTo(value)
	end
	cfValue.Value = model:GetPivot()
	cfValue.Changed:Connect(onChanged)

	local tween = TweenService:Create(cfValue, tweenInfo, {Value = targetCF})
	local con
	con = tween.Completed:Connect(function()
		if onComplete then
			onComplete()
		end
		con:Disconnect()
		con = nil
		cfValue:Destroy()
		cfValue = nil
		tween:Destroy()
		tween = nil
	end)
	tween:Play()
end

function module:ScaleParticleEmitter(emitter, scale)
	local keypoints = {}
	for _, v in emitter.Size.Keypoints do
		table.insert(keypoints, NumberSequenceKeypoint.new(v.Time, v.Value * scale, v.Envelope * scale))
	end
	emitter.Size = NumberSequence.new(keypoints)
end

function module:ResizeModel(model, scale)
	local origin = model.PrimaryPart.Position
	for _, v in model:GetDescendants() do
		if v:IsA("BasePart") then
			--v.Position = origin:Lerp(v.Position, scale)
			v.CFrame = CFrame.new(origin:Lerp(v.Position, scale)) * (v.CFrame - v.Position)
			v.Size *= scale
		elseif v:IsA("Attachment") then
			v.Position *= scale
		elseif v:IsA("ParticleEmitter") then
			module:ScaleParticleEmitter(v, scale)
		elseif v:IsA("JointInstance") then
			v.C0 = CFrame.new(v.C0.Position * scale) * (v.C0 - v.C0.Position)
			v.C1 = CFrame.new(v.C1.Position * scale) * (v.C1 - v.C1.Position)
		elseif v:IsA("SpecialMesh") then
			v.Scale *= scale
		end
	end
end

--// from https://devforum.roblox.com/t/878701
function module:TweenScaleModel(model, increment, duration, easingStyle, easingDirection)
	task.spawn(function()
		easingStyle = easingStyle or Enum.EasingStyle.Quad
		easingDirection = easingDirection or Enum.EasingDirection.Out
		local s = increment - 1
		local i = 0
		local oldAlpha = 0
		while i < 1 do
			local dt = task.wait()
			i = math.min(i + dt/duration, 1)
			local alpha = TweenService:GetValue(i, easingStyle, easingDirection)
			module:ResizeModel(model, (alpha*s + 1) / (oldAlpha*s + 1))
			oldAlpha = alpha
		end
	end)
end

function module:CreateIgnorePart()
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.Parent = workspace.Ignore
	return part
end

function module:PlaySoundInPart(sound, Part, Properties)
	local soundToPlay = Part:FindFirstChild(sound.Name)
	if not soundToPlay then
		soundToPlay = sound:Clone()
		soundToPlay.Parent = Part
	end
	if Properties then
		for property, Value in pairs(Properties) do
			soundToPlay[property] = Value
		end
	end
	soundToPlay:Play()
end


function module:PlaySoundAtPosition(sound, position, Properties)
	if typeof(position) == "Instance" and position:IsA("BasePart") then position = position.Position end
	local part = module:CreateIgnorePart()
	part.Name = "SoundNode"	
	part.CFrame = CFrame.new(position)

	local newSound = sound:Clone()
	newSound.Parent = part
	
	if Properties then
		for property, Value in pairs(Properties) do
			newSound[property] = Value
		end
	end

	local con
	con = newSound.Ended:Connect(function()
		con:Disconnect()
		con = nil
		part:Destroy()
	end)

	newSound:Play()
end

function module:EmitParticlesAtPosition(particles, position, emitNum, scale)
	emitNum = emitNum or 15
	local attachment = Instance.new("Attachment")
	attachment.Parent = workspace.Terrain
	attachment.Name = "ParticleNode"
	attachment.WorldPosition = position

	local particles = particles:Clone()
	if scale and scale ~= 1 then
		module:ScaleParticleEmitter(particles, scale)
	end
	particles.Parent = attachment
	task.delay(0.05, function() --// else they don't emit correctly
		particles:Emit(particles:GetAttribute("EmitCount") or emitNum)
		task.delay(particles.Lifetime.Max, function()
			attachment:Destroy()
		end)
	end)
end

function module:EmitParticlesOnPart(particles, parent, emitNum, position)
	emitNum = emitNum or 1
	local attachment = Instance.new("Attachment")
	attachment.Name = "ParticleNode"
	attachment.Position = position or Vector3.zero
	attachment.Parent = parent
	
	local particles = particles:Clone()
	particles.Parent = attachment
	task.delay(0.05, function() --// else they don't emit correctly
		particles:Emit(particles:GetAttribute("EmitCount") or emitNum)
		task.delay(particles.Lifetime.Max, function()
			attachment:Destroy()
		end)
	end)
end

function module:SafeClearUI(parent)
	for _, v in parent:GetChildren() do
		if not v:IsA("UILayout") and not v:IsA("UIConstraint") and not v:IsA("UIPadding") and not v:IsA("UIGradient") then
			v:Destroy()
		end
	end
end

--// take a Color3 and return an rgb string suitable for RichText format
function module:GetRGBString(color)
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return string.format("rgb(%s,%s,%s)", r, g, b)
end

--// reduceBounds lets you reduce the bounds by a percentage
--// this was a quick fix to make it so that I don't have to worry
--// about the size of the pet that is spawned in the box colliding with
--// the edge of the box
function module:GetRandomCFrameInBox(part, reduceBounds)
	local originCF = part.CFrame
	local size = part.Size
	if reduceBounds then
		size *= reduceBounds
	end
	return originCF * CFrame.new(
		math.random(-size.X/2,size.X/2),
		math.random(-size.Y/2,size.Y/2),
		math.random(-size.Z/2,size.Z/2))
end

function module:IsPointInArea(point, area)
	local areaPos, areaSize = area.Position, area.Size
	local halfAS = areaSize / 2

	if point.X > areaPos.X - halfAS.X and point.X < areaPos.X + halfAS.X then
		if point.Y > areaPos.Y - halfAS.Y and point.Y < areaPos.Y + halfAS.Y then
			if point.Z > areaPos.Z - halfAS.Z and point.Z < areaPos.Z + halfAS.Z then
				return true
			end
		end
	end
end

function module:IsPointInAreaXZ(point, area)
	local areaPos, areaSize = area.Position, area.Size
	local halfAS = areaSize / 2

	if point.X > areaPos.X - halfAS.X and point.X < areaPos.X + halfAS.X then
		if point.Z > areaPos.Z - halfAS.Z and point.Z < areaPos.Z + halfAS.Z then
			return true
		end
	end
end

function module:IsPointInRadius(point, origin, radius)
	local distance = (point - origin).Magnitude
	return distance <= radius
end

function module:CreatePolygonFromPoints(points)
	local polygon = {Position = points[1]}
	local first = polygon
	for i = 2, #points do
		polygon.Next = {Previous = polygon, Position = points[i]}
		polygon = polygon.Next
	end
	polygon.Next, first.Previous = first, polygon
	return first
end

function module:IsPointInsidePolygon(point, polygon)
	local current = polygon
	local inside = false
	local A = current.Position
	local ax, az = A.X, A.Z
	local px, pz = point.X, point.Z
	repeat
		local B = current.Next.Position
		local bx, bz = B.X, B.Z
		if ((az >= pz) ~= (bz >= pz)) and ((px - ax) <= (bx - ax)*(pz - az)/(bz - az)) then
			inside = not inside
		end
		current = current.Next
		A, ax, az = B, bx, bz
	until current == polygon
	return inside
end

function module:ClampPositionToBounds(targetPos, clampPart)
	local clampPos, clampSize = clampPart.Position, clampPart.Size
	local minCorner = Vector3.new(clampPos.X - clampSize.X/2, clampPos.Y - clampSize.Y/2, clampPos.Z - clampSize.Z/2)
	local maxCorner = Vector3.new(clampPos.X + clampSize.X/2, clampPos.Y + clampSize.Y/2, clampPos.Z + clampSize.Z/2)
	return Vector3.new(
		math.clamp(targetPos.X, minCorner.X, maxCorner.X),
		math.clamp(targetPos.Y, minCorner.Y, maxCorner.Y),
		math.clamp(targetPos.Z, minCorner.Z, maxCorner.Z)
	)
end

function module:ClampCFrameToBounds(targetCF, clampPart)
	local angles = CFrame.Angles(targetCF:ToEulerAnglesXYZ())
	local clampPos, clampSize = clampPart.Position, clampPart.Size
	local minCorner = Vector3.new(clampPos.X - clampSize.X/2, clampPos.Y - clampSize.Y/2, clampPos.Z - clampSize.Z/2)
	local maxCorner = Vector3.new(clampPos.X + clampSize.X/2, clampPos.Y + clampSize.Y/2, clampPos.Z + clampSize.Z/2)
	return CFrame.new(
		math.clamp(targetCF.X, minCorner.X, maxCorner.X),
		math.clamp(targetCF.Y, minCorner.Y, maxCorner.Y),
		math.clamp(targetCF.Z, minCorner.Z, maxCorner.Z)
	) * angles
end

--// weight tables should be dictionaries {result : weight}
local rand = Random.new()
function module:WeightedRandom(weights)
	local totalWeight = 0

	for _, weight in weights do
		totalWeight += weight
	end

	local chance = rand:NextInteger(1, totalWeight)
	local counter = 0
	for result, weight in weights do
		counter += weight
		if chance <= counter then
			return result
		end
	end
	
	return warn("WEIGHTED RANDOMIZATION FAILED")
end

function module:MakeDebugPart(pos, lifetime, color)
	local part = Instance.new("Part")
	part.Name = "DEBUG_PART"
	part.BrickColor = color or (game:GetService("RunService"):IsServer() and BrickColor.new("Bright green") or BrickColor.new("Bright blue"))
	part.Size = Vector3.one
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	if typeof(pos) == "CFrame" then
		part.CFrame = pos
	elseif typeof(pos) == "Vector3" then
		part.CFrame = CFrame.new(pos)
	elseif typeof(pos) == "Instance" and pos:IsA("BasePart") then
		part.CFrame = pos.CFrame
	end
	part.Parent = workspace.Ignore

	if lifetime then
		task.delay(lifetime, function()
			part:Destroy()
		end)
	end

	return part
end

function module:Lerp(a, b, t)
	return a + (b - a) * t
end

function module:SeparateWordsInPascalCase(str)
	str = str:gsub("%s+", "") --// remove whitespace just in case of "Pascal   Case"
	local newStr = ""
	for i = 1, #str do
		local thisLetter = str:sub(i, i)
		if i > 1 and thisLetter:match("%u") then
			newStr = newStr .. " "
		end
		newStr = newStr .. thisLetter
	end
	return newStr
end

function module:Weld(p0, p1, weldType)
	local w = Instance.new(weldType or "Weld", p0)
	w.C1 = p1.CFrame:ToObjectSpace(p0.CFrame)
	w.Part0 = p0
	w.Part1 = p1
	w.Name = p0.Name .. "To" .. p1.Name .. "Weld"
	return w
end

function module:WeldTool(tool)
	local handle = tool:FindFirstChild("Handle", true)
	if not handle then
		return warn("Cannot Weld", tool:GetFullName(), "because no handle found")
	end

	for _, v in tool:GetChildren() do
		if v:IsA("BasePart") and v ~= handle then
			module:Weld(handle, v)
			v.Anchored = false
		end
	end
end

function module:WeldModel(model)
	local primaryPart = model.PrimaryPart
	if not primaryPart then
		return warn("Cannot Weld", model:GetFullName(), "because no PrimaryPart found")
	end

	for _, v in model:GetChildren() do
		if v:IsA("BasePart") and v ~= primaryPart then
			module:Weld(primaryPart, v)
			v.Anchored = false
		end
	end
end

function module:WeldFromAttachments(attachmentA, attachmentB, name, className)
	local newMotor = Instance.new(className or "Motor6D")
	newMotor.C0 = attachmentA.CFrame
	newMotor.C1 = attachmentB.CFrame
	newMotor.Part0 = attachmentA.Parent
	newMotor.Part1 = attachmentB.Parent
	if name then
		newMotor.Name = name
	end
	newMotor.Parent = attachmentA.Parent
	return newMotor
end

function module:GenerateGUID(length)
	length = length or 8
	return HttpService:GenerateGUID(false):sub(1, length):upper():gsub('[^%dA-F]', "")
end

function module:deepSearchFolder(Folder,Type,InfoTable)
	local NewTable = InfoTable or {}
	Type = Type or "Animation"

	local Children = Folder:GetChildren()

	for i,Object in ipairs(Children) do
		if Object:IsA(Type) then
			NewTable[#NewTable + 1] = Object
		elseif Object:IsA("Folder") or Object:IsA("ModuleScript") then
			self:deepSearchFolder(Object,Type,NewTable)
		end
	end

	return NewTable
end

function module:DeepCopyTable(tab)
	local copy = {}
	for i, v in tab do
		if type(v) == "table" then
			copy[i] = module:DeepCopyTable(v)
		else
			copy[i] = v
		end
	end
	return copy
end

function module:TuneBrightness(color, modifier)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, v * modifier)
end

local function addZero(num)
	if num < 10 then
		return "0" .. num
	end
	return tostring(num)
end

function module:GetUnitsOfTime(seconds)
	local days = math.floor(seconds / 86400)
	seconds -= (days * 86400)
	local hours = math.floor(seconds / 3600)
	seconds -= (hours * 3600)
	local mins = math.floor(seconds / 60)
	seconds -= (mins * 60)

	return {Days = days, Hours = hours, Mins = mins, Seconds = seconds}
end

function module:FormatTime(seconds, highestMeasurement)
	local units = module:GetUnitsOfTime(seconds)

	if tostring(highestMeasurement):lower() == "days" then
		return string.format("%s:%s:%s:%s", units.Days, addZero(units.Hours), addZero(units.Mins), addZero(seconds))
	elseif tostring(highestMeasurement):lower() == "mins" then
		return string.format("%s:%s", addZero(units.Mins), addZero(units.Seconds))
	else
		return string.format("%s:%s:%s", addZero(units.Hours), addZero(units.Mins), addZero(units.Seconds))
	end
end

function module:FormatTimeShorthand(seconds)
	seconds = math.floor(seconds)
	local units = module:GetUnitsOfTime(seconds)
	local timeLeft = ""
	if units.Days > 0 then
		return ("%sd %sh"):format(units.Days, units.Hours)
	elseif units.Hours > 0 then
		return ("%sh %sm"):format(units.Hours, units.Mins)
	elseif units.Mins > 0 then
		if units.Seconds > 0 then
			return ("%sm %ss"):format(units.Mins, units.Seconds)
		else
			return units.Mins .. "m"
		end
	elseif units.Seconds > 0 then
		return units.Seconds .. "s"
	else --// lazy solution instead of returning -1s, -2s, etc
		return "0s"
	end
end

function module:GetMouseLocation()
	local mouseLocation = UserInputService:GetMouseLocation()
	return mouseLocation - Vector2.new(0, 32) --// account for IgnoreGUIInset being false
end


function module:CreateHitbox(model)
	local cf, size = model:GetBoundingBox()
	local part = Instance.new("Part")
	part.Name = "Bounds"
	part.Material = "SmoothPlastic"
	part.CastShadow = false
	part.BrickColor = BrickColor.new("Bright orange")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = size
	part.CFrame = cf
	part.Parent = model
	return part
end

function module:IsPlayerWithinRange(player, position, range)
	local char = player.Character
	return char and (char:GetPivot().Position - position).Magnitude <= range
end

--// emits all particles under an object
function module:EmitAllParticles(obj)
	for _, particle in obj:GetChildren() do
		if particle:IsA("ParticleEmitter") then
			particle:Emit(particle:GetAttribute("EmitCount") or 1)
		end
	end
end

function module:ToggleAllParticles(obj, bool)
	for _, particle in obj:GetChildren() do
		if particle:IsA("ParticleEmitter") or particle:IsA("Light") then
			particle.Enabled = bool
		end
	end
end

function module:SetCharacterVisibility(char, visible, transparency)
	if not char then return end
	
	--// if you want the char to be transparent but dont specify what level of transparency, assume fully invis
	if not visible then
		if not transparency then transparency = 1 end
		char:SetAttribute("Visible", false)
	else
		char:SetAttribute("Visible", true)

	end
	
	local function SetObjectTransparency(v)
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			local newTransparency

			if visible then
				local origTransparency = v:FindFirstChild("OriginalTransparency")
				if origTransparency then
					newTransparency = origTransparency.Value
				end
			else
				local origTransparency = v:FindFirstChild("OriginalTransparency")
				if not origTransparency then
					origTransparency = Instance.new("NumberValue")
					origTransparency.Name = "OriginalTransparency"
					origTransparency.Value = v.Transparency
					origTransparency.Parent = v
				end

				newTransparency = transparency
			end

			v.Transparency = newTransparency
		elseif v:IsA("BillboardGui") then
			if visible then
				v.Enabled = true
			else
				v.Enabled = false
			end
		elseif v:IsA("Decal") and v.Name == "face" then
			if visible then
				local val = v:FindFirstChild("FaceTexture")
				if val then
					v.Texture = val.Value
					val:Destroy()
				end
			else --// have to remove and put back the texture because roblox doesnt replicate character decal transparency to the client
				if v:FindFirstChild("FaceTexture") then
					v.FaceTexture:Destroy()
				end

				local val = Instance.new("StringValue")
				val.Name = "FaceTexture"
				val.Value = v.Texture
				val.Parent = v

				v.Texture = ""
			end
		end
	end

	for _, v in char:GetDescendants() do
		SetObjectTransparency(v)
	end
	
	if not visible then
		local con
		con = char.ChildAdded:Connect(function(c)
			if char:GetAttribute("Visible") then
				con:Disconnect()
				con = nil
			end
			if c:IsA("Model") then
				for i, v in pairs(c:GetDescendants()) do
					SetObjectTransparency(v)
				end
			else
				SetObjectTransparency(c)
			end
		end)
	end
	
end

function module:CoverPartInAttachments(part, attachmentName, visualize)
	local padding = 0.5 
	local size = part.Size
	local positions = {}


	-- Top and Bottom surfaces
	for X = -(size.X / 2) + padding, (size.X / 2) - padding, padding do
		for Z = -(size.Z / 2) + padding, (size.Z / 2) - padding, padding do
			table.insert(positions, Vector3.new(X, size.Y / 2, Z)) -- Top surface
			table.insert(positions, Vector3.new(X, -(size.Y / 2), Z)) -- Bottom surface
		end
	end

	-- Front and Back surfaces
	for X = -(size.X / 2) + padding, (size.X / 2) - padding, padding do
		for Y = -(size.Y / 2) + padding, (size.Y / 2) - padding, padding do
			table.insert(positions, Vector3.new(X, Y, size.Z / 2)) -- Front surface
			table.insert(positions, Vector3.new(X, Y, -(size.Z / 2))) -- Back surface
		end
	end

	-- Left and Right surfaces
	for Y = -(size.Y / 2) + padding, (size.Y / 2) - padding, padding do
		for Z = -(size.Z / 2) + padding, (size.Z / 2) - padding, padding do
			table.insert(positions, Vector3.new(size.X / 2, Y, Z)) -- Right surface
			table.insert(positions, Vector3.new(-(size.X / 2), Y, Z)) -- Left surface
		end
	end
	for _, position in pairs(positions) do
		local attachment = Instance.new("Attachment", part)
		attachment.Name = attachmentName
		attachment.Visible = visualize or false
		attachment.WorldPosition = part.Position + position
	end	
end


function module:CalculateMaxExp(level)
    local BaseMaxExp = 100
    local ExpIncrease = 45
    
    return BaseMaxExp + (level - 1) * ExpIncrease
end


return module