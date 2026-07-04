-- // Rayfield Bootstrapper
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // Variables & Original States
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local OriginalSettings = {
    Ambient = Lighting.Ambient, 
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness, 
    GlobalShadows = Lighting.GlobalShadows, 
    FogEnd = Lighting.FogEnd
}

local espEnabled = false
local espHighlights = {}

-- // Window Creation
local Window = Rayfield:CreateWindow({
    Name = "Streamlined troll em 5.0 | STE 5",
    LoadingTitle = "Loading STE 5...",
    LoadingSubtitle = "by You",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "STE5"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true 
    },
    KeySystem = false
})

-- // Tabs
local TabHubs = Window:CreateTab("Hubs & Admin", 4483362458)
local TabPlayer = Window:CreateTab("Player & Troll", 4483362458)
local TabGames = Window:CreateTab("Game Scripts", 4483362458)
local TabVisuals = Window:CreateTab("Visuals", 4483362458)

-- ==========================================
-- Hubs & Admin Tab
-- ==========================================
TabHubs:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end,
})

TabHubs:CreateButton({
    Name = "Dex Explorer",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))()
    end,
})

-- ==========================================
-- Player & Troll Tab
-- ==========================================
TabPlayer:CreateButton({
    Name = "God HP (Local)",
    Callback = function()
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.MaxHealth = 1000000000000
            char.Humanoid.Health = 1000000000000
        end
    end,
})

TabPlayer:CreateButton({
    Name = "Invisible Gui",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Invisible%20Gui'))()
    end,
})

TabPlayer:CreateButton({
    Name = "Ultimate Fling",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))()
    end,
})

TabPlayer:CreateButton({
    Name = "Teleportica (Teleport 1)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Telxr/Teleportica/refs/heads/main/Telepo"))()
    end,
})

TabPlayer:CreateButton({
    Name = "Pastebin TP (Teleport 2)",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/AbDM2er1"))()
    end,
})

-- ==========================================
-- Game Scripts Tab
-- ==========================================
TabGames:CreateButton({
    Name = "Work at a Pizza Place Troll",
    Callback = function()
        loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/blueEa1532/thechosenone/refs/heads/main/trollpizzagui"))()
    end,
})

TabGames:CreateButton({
    Name = "MM2 Script (Vertex Hub)",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Vertex-Hub/Vertex/main/Main.lua'))()
    end,
})

TabGames:CreateButton({
    Name = "MM2 Script (SmokingScripts)",
    Callback = function()
        loadstring(game:HttpGet('https://raw.smokingscripts.org/vertex.lua'))()
    end,
})

-- ==========================================
-- Visuals Tab
-- ==========================================
TabVisuals:CreateToggle({
    Name = "Eagle Eye (ESP)",
    CurrentValue = false,
    Flag = "ToggleESP",
    Callback = function(Value)
        espEnabled = Value
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= Players.LocalPlayer and p.Character then
                    local h = Instance.new("Highlight")
                    h.Parent = p.Character
                    h.FillColor = Color3.new(1, 0, 0)
                    table.insert(espHighlights, h)
                end
            end
        else
            for _, h in pairs(espHighlights) do
                if h and h.Parent then
                    h:Destroy()
                end
            end
            table.clear(espHighlights)
        end
    end,
})

TabVisuals:CreateButton({
    Name = "Night Vision",
    Callback = function()
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
    end,
})

TabVisuals:CreateButton({
    Name = "Restore Graphics",
    Callback = function()
        Lighting.Ambient = OriginalSettings.Ambient
        Lighting.OutdoorAmbient = OriginalSettings.OutdoorAmbient
        Lighting.Brightness = OriginalSettings.Brightness
        Lighting.GlobalShadows = OriginalSettings.GlobalShadows
        Lighting.FogEnd = OriginalSettings.FogEnd
    end,
})

Rayfield:LoadConfiguration()
