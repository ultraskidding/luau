-- made by locality 
-- found this method - 19.12.2025 (dd mm yyyy)

local AkaliNotif = loadstring(game:HttpGet("https://raw.githubusercontent.com/ultraskidding/luau/refs/heads/main/AkaliNotif.lua"))();
local Notify = AkaliNotif.Notify;

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local ScriptNotify = ReplicatedStorage.GamepassEvents.MulticolorLineBoughtNotifier
local Activator = ReplicatedStorage.MenuToys.LimitedTimeToyEvent
local function ReloadScript()
    LocalPlayer.PlayerGui.MenuGui.Menu.TabContents.Settings.Contents.LineFrame.ColorPicking.Enabled = false
    LocalPlayer.PlayerGui.MenuGui.Menu.TabContents.Settings.Contents.LineFrame.ColorPicking.Enabled = true
end

Notify({
    Title = "Multicolor Line",
    Description = "Activated! (no toggle)",
    Duration = 5
})

ScriptNotify.Parent = workspace
Activator.Parent = ReplicatedStorage.GamepassEvents
Activator.Name = "MulticolorLineBoughtNotifier"

ReloadScript()
task.delay(0.1, function()
    Activator:FireServer()
end)
Toggle(true)
