local runService = game:GetService("RunService")
 
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local smoothening = 0.2
function updateBobbleEffect(deltaTime)
    local currentTime = tick()
    if humanoid.MoveDirection.Magnitude > 0 and character:GetAttribute("Sprinting") and not character:GetAttribute("LedgeGrabbing") then -- we are walking
        local bobbleX = math.cos(currentTime * 10) * .35
        local bobbleY = math.abs(math.sin(currentTime * 10)) * .35
        
        local bobble = Vector3.new(bobbleX, bobbleY, 0)
        
        humanoid.CameraOffset = humanoid.CameraOffset:lerp(bobble,  math.clamp(smoothening * deltaTime * 60, 0, 1))
    else -- we are not walking
        humanoid.CameraOffset = humanoid.CameraOffset * .75
    end
end
 
runService.RenderStepped:Connect(updateBobbleEffect)