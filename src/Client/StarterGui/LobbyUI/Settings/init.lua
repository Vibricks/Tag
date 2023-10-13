local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

local LobbyUI = Player:WaitForChild("PlayerGui"):WaitForChild("LobbyUI")
local Settings = LobbyUI:WaitForChild("Settings")

local SFX = game:GetService("SoundService").SFX

local Knit = require(ReplicatedStorage.Packages.Knit)

local Shared = require(script.Parent.Shared)
local module = {}
local Connections = {}



local StatService =  Knit.GetService("StatService")
local ReplicaInterfaceController = Knit.GetController("ReplicaInterfaceController")
local PlayerProfileReplica = ReplicaInterfaceController:GetReplica("PlayerProfile")


local function updateCheckbox(Bool, Checkbox)
   if Bool == true then
        Checkbox.BackgroundColor3 = Color3.fromRGB(44, 244, 107)
        Checkbox.Icon.Image = "rbxassetid://69805477"
        Checkbox:SetAttribute("Bool", true)
   else
        Checkbox.BackgroundColor3 = Color3.fromRGB(244, 22, 74)
        Checkbox.Icon.Image = "rbxassetid://9545003266"
        Checkbox:SetAttribute("Bool", false)
   end
end


local SettingFunctions = {
    ["AutoSprint"] = function(Bool, Update)
        if Update then StatService:ChangeSetting("AutoSprint", Bool) end
    end,

    ["BackgroundMusic"] = function(Bool, Update)
        if Update then
            StatService:ChangeSetting("BackgroundMusic", Bool)
        end
        workspace.RoundMusic.Volume = 0
    end
}

local Debounces = {}

for i, v in pairs(Settings.MainFrame.Container:GetChildren()) do
    local Checkbox = v:FindFirstChild("Checkbox") 
    if Checkbox then
        local presetBool = PlayerProfileReplica.Data.Settings[v.Name]
        if presetBool == true or presetBool == false then
            updateCheckbox(presetBool, Checkbox)
            SettingFunctions[v.Name](presetBool, true)
        end
        Checkbox.Button.MouseButton1Click:Connect(function()
            if Debounces[Checkbox] then return end
            Debounces[Checkbox] = true
            SFX.Click:Play()
            local newBool = not Checkbox:GetAttribute("Bool")
            SettingFunctions[v.Name](newBool, true)
            updateCheckbox(newBool, Checkbox)
            task.wait(.5)
            Debounces[Checkbox] = false
        end)
    end
end

function module:Toggle(Bool)
    local function Close()
        Settings.Visible = false
        Shared.CurrentFrame = nil
        game.Lighting.UI_BLUR.Enabled = false
    end
    if Bool == true then
        Settings.Visible = true
        Shared.CurrentFrame = Settings
        --* Connecting to the close button
        if not Connections["Close"] then
            local closeButton = Settings.MainFrame.Close
            Connections ["Close"] = closeButton.Button.MouseButton1Click:Connect(function()
                SFX.Click:Play()
                Close()
            end)
        end
    else
        Close()
    end
end

return module