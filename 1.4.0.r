pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/raavenkkj/anti-kick/main/anti-kick.lua"))()
    getgenv().AntiKick = true
    getgenv().Notifications = true
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local _G = {
    flySpeed = 50, flying = false, infJump = false, noclip = false, predator = false,
    esp = false, sawnick = false, ghoul = false, jetpack = false, target = "s"
}

local function GetTargets()
    local text = _G.target:lower()
    local victims = {}
    if text == "all" then return Players:GetPlayers()
    elseif text == "others" then 
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(victims, p) end end
    elseif text == "s" or text == "me" then return {LP}
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():find(text) or p.DisplayName:lower():find(text) then 
                table.insert(victims, p) 
            end
        end
    end
    return victims
end

local Window = Rayfield:CreateWindow({
    Name = "ULTIMATE TROLL EM 4.0",
    LoadingTitle = "Hello, user!",
    LoadingSubtitle = "Seraphic Edition",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab("Trolls", 4483362458)
local ScriptTab = Window:CreateTab("Scripts", 4483362458)
local HubTab = Window:CreateTab("Auto Hub", 4483362458)

MainTab:CreateInput({
    Name = "Target",
    PlaceholderText = "Username / all / others / s",
    Callback = function(Text) _G.target = Text end,
})

MainTab:CreateSection("Movement")

MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value) _G.flying = Value end,
})

MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 10,
    CurrentValue = 50,
    Callback = function(Value) _G.flySpeed = Value end,
})

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value) _G.noclip = Value end,
})

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value) _G.infJump = Value end,
})

MainTab:CreateToggle({
    Name = "Sawnick (Speed)",
    CurrentValue = false,
    Callback = function(Value) 
        _G.sawnick = Value
        LP.Character.Humanoid.WalkSpeed = Value and 500 or 16 
    end,
})

MainTab:CreateSection("Targeting & Combat")

MainTab:CreateButton({
    Name = "Max Hitbox",
    Callback = function()
        for _, p in pairs(GetTargets()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(30, 30, 30)
                p.Character.HumanoidRootPart.Transparency = 0.7
                p.Character.HumanoidRootPart.CanCollide = false
            end
        end
    end,
})

MainTab:CreateButton({
    Name = "Smallest Hitbox",
    Callback = function()
        for _, p in pairs(GetTargets()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(0.1, 0.1, 0.1)
                p.Character.HumanoidRootPart.Transparency = 0
            end
        end
    end,
})

MainTab:CreateButton({
    Name = "Default Hitbox",
    Callback = function()
        for _, p in pairs(GetTargets()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                p.Character.HumanoidRootPart.Transparency = 0
            end
        end
    end,
})

MainTab:CreateToggle({
    Name = "Orbit Target",
    CurrentValue = false,
    Callback = function(Value) _G.predator = Value end,
})

MainTab:CreateButton({
    Name = "TP to Target",
    Callback = function()
        local t = GetTargets()[1]
        if t and t.Character then LP.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame end
    end,
})

MainTab:CreateSection("Visuals & Stats")

MainTab:CreateToggle({
    Name = "ESP Highlights",
    CurrentValue = false,
    Callback = function(Value)
        _G.esp = Value
        for _,p in pairs(Players:GetPlayers()) do
            if p.Character then
                if _G.esp then Instance.new("Highlight", p.Character) else
                    if p.Character:FindFirstChild("Highlight") then p.Character.Highlight:Destroy() end
                end
            end
        end
    end,
})

MainTab:CreateToggle({
    Name = "Ghoul Mode",
    CurrentValue = false,
    Callback = function(Value)
        _G.ghoul = Value
        _G.noclip = Value
        if LP.Character then
            for _,v in pairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.Transparency = Value and 0.5 or 0 end
            end
        end
    end,
})

MainTab:CreateButton({
    Name = "Tanker (Infinite Health)",
    Callback = function()
        LP.Character.Humanoid.MaxHealth = 100000
        LP.Character.Humanoid.Health = 100000
    end,
})

ScriptTab:CreateSection("Power Tools")
ScriptTab:CreateButton({Name = "Seraphic Blade", Callback = function() loadstring(game:HttpGet("https://pastefy.app/59mJGQGe/raw"))() end})
ScriptTab:CreateButton({Name = "Nameless Admin", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source'))() end})
ScriptTab:CreateButton({Name = "Infinite Yield", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end})
ScriptTab:CreateButton({Name = "Gun Script", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/0hn40Zbc"))() end})
ScriptTab:CreateButton({Name = "Fling GUI", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))() end})
ScriptTab:CreateButton({Name = "Invisible GUI", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Invisible%20Gui'))() end})

ScriptTab:CreateSection("Development & Debug")
ScriptTab:CreateButton({Name = "Dex Explorer", Callback = function() loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Dex%20Explorer.lua"))() end})
ScriptTab:CreateButton({Name = "Simple Spy", Callback = function() loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))() end})
ScriptTab:CreateButton({Name = "Script Searcher", Callback = function() loadstring(game:HttpGet("https://pastefy.app/cIrUcSTO/raw"))() end})
ScriptTab:CreateButton({Name = "Master Execute (IY + Spy)", Callback = function() 
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() 
    loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpyV2/master/simple-spy-v3.lua"))() 
end})

local HubGames = {
    [994732206] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/main/Blox%20Fruit.lua",
    [1268927906] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/main/Muscle%20Legends.lua",
    [3808081382] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/main/The%20Strongest%20Battleground.lua",
    [6401952734] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/main/Pet%20GO.lua",
    [5750914919] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/main/Fisch.lua",
    [7436755782] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/refs/heads/main/Grow%20a%20Garden.lua",
    [6701277882] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/refs/heads/main/Fish%20It.lua",
    [7671049560] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/refs/heads/main/The%20Forge.lua",
    [9363735110] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/refs/heads/main/Escape%20Tsunami%20For%20Brainrots.lua",
    [8144728961] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/refs/heads/main/Abyss.lua",
    [9509842868] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/refs/heads/main/Garden%20Horizons.lua",
    [9186719164] = "https://raw.githubusercontent.com/AhmadV99/Script-Games/refs/heads/main/Sailor%20Piece.lua"
}

HubTab:CreateButton({
    Name = "Detect & Load Game Script",
    Callback = function()
        local placeId = game.PlaceId
        if HubGames[placeId] then 
            loadstring(game:HttpGet(HubGames[placeId]))() 
            Rayfield:Notify({Title = "Success", Content = "Loaded script for Game ID: "..placeId, Duration = 5, Image = 4483362458})
        else 
            Rayfield:Notify({Title = "Not Found", Content = "No custom script for this game ID.", Duration = 5, Image = 4483362458})
        end
    end,
})

RunService.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        if _G.noclip then 
            for _,v in pairs(LP.Character:GetDescendants()) do 
                if v:IsA("BasePart") then v.CanCollide = false end 
            end 
        end
        if _G.flying then 
            LP.Character.HumanoidRootPart.Velocity = Camera.CFrame.LookVector * _G.flySpeed 
        end
        if _G.predator then 
            local t = GetTargets()[1] 
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then 
                LP.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,5) 
            end 
        end
    end
end)

UIS.JumpRequest:Connect(function() 
    if _G.infJump and LP.Character:FindFirstChild("Humanoid") then 
        LP.Character.Humanoid:ChangeState("Jumping") 
    end 
end)
