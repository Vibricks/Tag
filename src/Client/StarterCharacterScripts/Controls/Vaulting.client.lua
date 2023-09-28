local plr = game:GetService("Players").LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local Hum = char:WaitForChild("Humanoid")
local Animator = Hum:WaitForChild("Animator")
local CA = Animator:LoadAnimation(game.ReplicatedStorage.Assets.Animations.Movement.Vaulting)
local ledgeavail = true

while game:GetService("RunService").RenderStepped:Wait() do
	local r = Ray.new(HRP.Position, HRP.CFrame.LookVector * 7 + HRP.CFrame.UpVector * -5)
	local part = workspace:FindPartOnRay(r,char)

	if part and ledgeavail then
		if part.Name  == "Vault" or part.Parent.Name == "Vault" or part.Parent.Parent.Name == "Vault" then
			if Hum.FloorMaterial ~= Enum.Material.Air then
				ledgeavail = false
				local Vel = Instance.new("BodyVelocity")
				Vel.Parent = HRP
				Vel.Velocity = Vector3.new(0,0,0)
				Vel.MaxForce = Vector3.new(1,1,1) * math.huge
				Vel.Velocity = HRP.CFrame.LookVector * 20 + Vector3.new(0,30,0)
				CA:Play()
				game.Debris:AddItem(Vel, .15)
				task.wait(0.75)
				CA:Stop()
				ledgeavail = true
			end
		end
	end
end