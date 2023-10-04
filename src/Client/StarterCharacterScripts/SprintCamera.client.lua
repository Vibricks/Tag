local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local StateReader = require(ReplicatedStorage.Shared.StateReader)

Knit.OnStart()
	:andThen(function()
		local character = script.Parent
		local humanoid = character:WaitForChild("Humanoid")
		local smoothening = 0.2
		local function updateBobbleEffect(deltaTime)
			local currentTime = tick()
			local IsLedgeGrabbing = StateReader:IsStateEnabled(character, "LedgeGrabbing")
			local IsSprinting = StateReader:IsStateEnabled(character, "Sprinting")

			if humanoid.MoveDirection.Magnitude > 0 and IsSprinting and not IsLedgeGrabbing then -- we are walking
				local bobbleX = math.cos(currentTime * 10) * 0.35
				local bobbleY = math.abs(math.sin(currentTime * 10)) * 0.35

				local bobble = Vector3.new(bobbleX, bobbleY, 0)

				humanoid.CameraOffset =
					humanoid.CameraOffset:lerp(bobble, math.clamp(smoothening * deltaTime * 60, 0, 1))
			else -- we are not walking
				humanoid.CameraOffset = humanoid.CameraOffset * 0.75
			end
		end

		runService.RenderStepped:Connect(updateBobbleEffect)
	end)
	:catch()
