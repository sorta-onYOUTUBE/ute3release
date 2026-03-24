-- [[ ULTIMATE TROLL EM V3.01 - THE COMPLETE ADAPTIVE FLAGSHIP ]]
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "ULTIMATE_TROLL_EM_3.01"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- [[ GLOBAL STATE ]]
local _G = {
    r = 25, g = 150, b = 255, 
    bg_r = 15, bg_g = 15, bg_b = 15, bg_op = 0.6,
    flySpeed = 50, flying = false, infJump = false, noclip = false, predator = false,
    esp = false, sawnick = false, ghoul = false, tank = false, jetpack = false,
    target = "s", grid = 15, tileSize = 85, buildMode = false,
    States = {}, Positions = {}
}

local CommandLogic = {} 
local UI_Registry = {Buttons = {}, Accents = {}}
local ConfigFile = "TrollEm_V3_01.json"

-- [[ DATA SYSTEM ]]
local function SaveConfig()
    local data = {
        States = _G.States,
        Positions = _G.Positions,
        Colors = {_G.r, _G.g, _G.b}
    }
    pcall(function() writefile(ConfigFile, HttpService:JSONEncode(data)) end)
end

local function LoadConfig()
    if isfile(ConfigFile) then
        local s, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if s then
            _G.States = data.States or {}
            _G.Positions = data.Positions or {}
            if data.Colors then _G.r, _G.g, _G.b = unpack(data.Colors) end
        end
    end
end

-- [[ ACCENT & STYLE SYSTEM ]]
local function UpdateButtonStyle(btn)
    if _G.States[btn.Name] then
        btn.BackgroundColor3 = Color3.fromRGB(_G.r, _G.g, _G.b)
        btn.BackgroundTransparency = 0
    else
        btn.BackgroundColor3 = Color3.new(0, 0, 0)
        btn.BackgroundTransparency = 0.6
    end
end

local function SyncAccent(color)
    _G.r, _G.g, _G.b = color.R*255, color.G*255, color.B*255
    for _, btn in pairs(UI_Registry.Buttons) do UpdateButtonStyle(btn) end
    for _, txt in pairs(UI_Registry.Accents) do txt.TextColor3 = color end
end

-- [[ TARGETING ENGINE ]]
local function GetTargets()
    local text = _G.target:lower()
    local victims = {}
    if text == "all" then return Players:GetPlayers()
    elseif text == "others" then for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(victims, p) end end
    elseif text == "s" or text == "me" then return {LP}
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #text) == text or p.DisplayName:lower():sub(1, #text) == text then table.insert(victims, p) end
        end
    end
    return victims
end

-- [[ MAIN UI ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0.8, 0, 0.7, 0)
Main.Position = UDim2.new(0.5, 0, 0.45, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(_G.bg_r, _G.bg_g, _G.bg_b)
Main.BackgroundTransparency = _G.bg_op
Main.Visible = false; Main.BorderSizePixel = 0
local UIScale = Instance.new("UIScale", Main)

local SidePanel = Instance.new("Frame", Main)
SidePanel.Size = UDim2.new(0.25, 0, 0.95, 0); SidePanel.Position = UDim2.new(0.02, 0, 0.025, 0)
SidePanel.BackgroundColor3 = Color3.new(0,0,0); SidePanel.BackgroundTransparency = 0.5; SidePanel.BorderSizePixel = 0

local SideScroll = Instance.new("ScrollingFrame", SidePanel)
SideScroll.Size = UDim2.new(1, -10, 0.6, -10); SideScroll.Position = UDim2.new(0, 5, 0, 5)
SideScroll.BackgroundTransparency = 1; SideScroll.ScrollBarThickness = 2; SideScroll.AutomaticCanvasSize = "Y"
Instance.new("UIListLayout", SideScroll)

local ConsolePage = Instance.new("ScrollingFrame", SidePanel)
ConsolePage.Size = UDim2.new(1, -10, 0.35, -5); ConsolePage.Position = UDim2.new(0, 5, 0.65, 0)
ConsolePage.BackgroundColor3 = Color3.new(0,0,0); ConsolePage.BackgroundTransparency = 0.7; ConsolePage.AutomaticCanvasSize = "Y"
Instance.new("UIListLayout", ConsolePage).VerticalAlignment = "Bottom"

local CmdPage = Instance.new("ScrollingFrame", Main)
CmdPage.Size = UDim2.new(0.7, 0, 0.95, 0); CmdPage.Position = UDim2.new(0.28, 0, 0.025, 0)
CmdPage.BackgroundTransparency = 1; CmdPage.AutomaticCanvasSize = "Y"
CmdPage.ClipsDescendants = true

local Grid = Instance.new("UIGridLayout", CmdPage)
Grid.CellSize = UDim2.new(0, _G.tileSize, 0, _G.tileSize)
Grid.CellPadding = UDim2.new(0, 10, 0, 10)

-- [[ DRAG & REPEL ENGINE ]]
local function Snap(pos)
    local step = _G.grid
    local x = math.floor(pos.X.Offset / step + 0.5) * step
    local y = math.floor(pos.Y.Offset / step + 0.5) * step
    x = math.clamp(x, 0, CmdPage.AbsoluteSize.X - _G.tileSize)
    return UDim2.new(0, x, 0, y)
end

local function HandleRepel(movedBtn)
    for _, btn in pairs(UI_Registry.Buttons) do
        if btn ~= movedBtn then
            local dist = (Vector2.new(btn.Position.X.Offset, btn.Position.Y.Offset) - Vector2.new(movedBtn.Position.X.Offset, movedBtn.Position.Y.Offset)).Magnitude
            if dist < 15 then
                btn.Position = Snap(UDim2.new(0, btn.Position.X.Offset + (_G.tileSize + 10), 0, btn.Position.Y.Offset))
                _G.Positions[btn.Name] = {btn.Position.X.Offset, btn.Position.Y.Offset}
                HandleRepel(btn)
            end
        end
    end
end

local function makeDraggable(btn)
    local dragging, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if _G.buildMode and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            btn.ZIndex = 50
        end
    end)
    btn.InputEnded:Connect(function(input)
        if dragging then
            dragging = false
            btn.ZIndex = 1
            btn.Position = Snap(btn.Position)
            _G.Positions[btn.Name] = {btn.Position.X.Offset, btn.Position.Y.Offset}
            HandleRepel(btn)
            SaveConfig()
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = (input.Position - dragStart) / UIScale.Scale
            btn.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- [[ TASKBAR ]]
local Taskbar = Instance.new("Frame", ScreenGui)
Taskbar.Size = UDim2.new(1, 0, 0, 25); Taskbar.Position = UDim2.new(0, 0, 1, -25)
Taskbar.BackgroundColor3 = Color3.new(0,0,0); Taskbar.BackgroundTransparency = 0.7; Taskbar.Visible = false

local function styleInput(obj)
    obj.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1); obj.BackgroundTransparency = 0.5
    obj.TextColor3 = Color3.new(1, 1, 1); obj.Font = "Code"; obj.TextSize = 10; obj.BorderSizePixel = 0
end

local TBox = Instance.new("TextBox", Taskbar); TBox.Size = UDim2.new(0.08, 0, 0.8, 0); TBox.Position = UDim2.new(0.01, 0, 0.1, 0); TBox.Text = "Target: s"; styleInput(TBox)
TBox.FocusLost:Connect(function() _G.target = TBox.Text:gsub("Target: ", ""); TBox.Text = "Target: ".._G.target end)

local BuildBtn = Instance.new("TextButton", Taskbar); BuildBtn.Size = UDim2.new(0.07, 0, 0.8, 0); BuildBtn.Position = UDim2.new(0.1, 0, 0.1, 0); BuildBtn.Text = "Build Mode"; styleInput(BuildBtn)
local SaveBtn = Instance.new("TextButton", Taskbar); SaveBtn.Size = UDim2.new(0.05, 0, 0.8, 0); SaveBtn.Position = UDim2.new(0.18, 0, 0.1, 0); SaveBtn.Text = "Save"; styleInput(SaveBtn)
local ResetBtn = Instance.new("TextButton", Taskbar); ResetBtn.Size = UDim2.new(0.07, 0, 0.8, 0); ResetBtn.Position = UDim2.new(0.24, 0, 0.1, 0); ResetBtn.Text = "Reset UI"; styleInput(ResetBtn)

local TermInput = Instance.new("TextBox", Taskbar); TermInput.Size = UDim2.new(0.15, 0, 0.8, 0); TermInput.Position = UDim2.new(0.32, 0, 0.1, 0); TermInput.PlaceholderText = "Type command..."; styleInput(TermInput)

local MainToggle = Instance.new("TextButton", Taskbar); MainToggle.Size = UDim2.new(0, 80, 1, 0); MainToggle.Position = UDim2.new(1, -80, 0, 0); MainToggle.Text = "Open"; MainToggle.BackgroundColor3 = Color3.new(0.1,0.1,0.1); MainToggle.TextColor3 = Color3.fromRGB(_G.r,_G.g,_G.b); MainToggle.Font = "Code"; MainToggle.BorderSizePixel = 0
table.insert(UI_Registry.Accents, MainToggle)

-- [[ ENGINE ]]
local function logTerminal(msg, success)
    local l = Instance.new("TextLabel", ConsolePage); l.Size = UDim2.new(1,0,0,16); l.BackgroundTransparency = 1
    l.Text = "> " .. msg .. (success and " : OK" or " : ERR")
    l.TextColor3 = success and Color3.new(0,1,0.5) or Color3.new(1,0,0); l.Font = "Code"; l.TextSize = 10; l.TextXAlignment = "Left"
end

local function addCmd(n, cb)
    CommandLogic[n:lower()] = cb
    local l = Instance.new("TextLabel", SideScroll); l.Size = UDim2.new(1,0,0,14); l.BackgroundTransparency = 1
    l.Text = "- "..n; l.TextColor3 = Color3.new(0.8,0.8,0.8); l.Font = "Code"; l.TextSize = 10; l.TextXAlignment = "Left"
    
    local t = Instance.new("TextButton", CmdPage); t.Name = n; t.Text = n; t.Font = "Code"; t.BorderSizePixel = 0; t.TextWrapped = true; t.TextSize = 10; t.TextColor3 = Color3.new(1,1,1)
    
    if _G.Positions[n] then
        Grid.Enabled = false
        t.Position = UDim2.new(0, _G.Positions[n][1], 0, _G.Positions[n][2])
    end
    
    UpdateButtonStyle(t)
    makeDraggable(t)
    
    t.MouseButton1Click:Connect(function() 
        if not _G.buildMode then 
            _G.States[n] = not _G.States[n]
            local s, e = pcall(cb) 
            UpdateButtonStyle(t)
            logTerminal(n, s) 
            SaveConfig()
        end 
    end)
    table.insert(UI_Registry.Buttons, t)
end

-- [[ COMMAND DEFINITIONS ]]
addCmd("Fly", function() _G.flying = _G.States["Fly"] end)
addCmd("Noclip", function() _G.noclip = _G.States["Noclip"] end)
addCmd("InfJump", function() _G.infJump = _G.States["InfJump"] end)
addCmd("Sawnick", function() LP.Character.Humanoid.WalkSpeed = _G.States["Sawnick"] and 500 or 16 end)
addCmd("Admin", function() loadstring(game:HttpGet("https://gist.github.com/someunknowndude/38cecea5be9d75cb743eac8b1eaf6758/raw"))() end)
addCmd("TP", function() LP.Character.HumanoidRootPart.CFrame = GetTargets()[1].Character.HumanoidRootPart.CFrame end)
addCmd("Fling", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))() end)
addCmd("Orbit", function() _G.predator = _G.States["Orbit"] end)
addCmd("Invisible", function() loadstring(game:HttpGet(('https://raw.githubusercontent.com/Mohamedguguu/invisible-V1-BY-MU/refs/heads/main/Maincode'),true))() end)
addCmd("ESP", function() 
    _G.esp = _G.States["ESP"]
    for _,p in pairs(Players:GetPlayers()) do 
        if p.Character then 
            if _G.esp then Instance.new("Highlight", p.Character) else if p.Character:FindFirstChild("Highlight") then p.Character.Highlight:Destroy() end end 
        end 
    end 
end)
addCmd("InfYield", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
addCmd("Dex", function() loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Dex%20Explorer.lua"))() end)
addCmd("Jetpack", function() _G.jetpack = _G.States["Jetpack"]; _G.flying = _G.jetpack; _G.flySpeed = 100 end)
addCmd("Ghoul", function() 
    _G.ghoul = _G.States["Ghoul"]; _G.noclip = _G.ghoul
    if LP.Character then for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.Transparency = _G.ghoul and 0.5 or 0 end end end
end)
addCmd("Mini Troll Em", function()
    if game.CoreGui:FindFirstChild("Trollem10") then game.CoreGui.Trollem10:Destroy() end
    local MiniGui = Instance.new("ScreenGui", game.CoreGui); MiniGui.Name = "Trollem10"
    local MF = Instance.new("Frame", MiniGui); MF.BackgroundColor3 = Color3.fromRGB(30,30,30); MF.Size = UDim2.new(0,200,0,300); MF.Position = UDim2.new(0.1,0,0.1,0); MF.Active = true; MF.Draggable = true
    local T = Instance.new("TextLabel", MF); T.Size = UDim2.new(1,0,0,30); T.Text = "Troll em 1.0"; T.BackgroundColor3 = Color3.fromRGB(60,0,150); T.TextColor3 = Color3.new(1,1,1)
    local GP = Instance.new("Frame", MiniGui); GP.Size = UDim2.new(0,220,0,320); GP.Position = UDim2.new(0.3,0,0.1,0); GP.BackgroundColor3 = Color3.fromRGB(40,40,40); GP.Visible = false; GP.Active = true; GP.Draggable = true
    local function cB(n, tx, p, par, col)
        local b = Instance.new("TextButton", par); b.Text = tx; b.Position = p; b.Size = UDim2.new(0.85,0,0,35); b.BackgroundColor3 = col or Color3.fromRGB(50,50,50); b.TextColor3 = Color3.new(1,1,1)
        return b
    end
    cB("IY", "Inf Yield", UDim2.new(0.07,0,0.15,0), MF).MouseButton1Click:Connect(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
    cB("Dex", "Dex", UDim2.new(0.07,0,0.3,0), MF).MouseButton1Click:Connect(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))() end)
    cB("HP", "God HP", UDim2.new(0.07,0,0.45,0), MF).MouseButton1Click:Connect(function() LP.Character.Humanoid.MaxHealth = 1e12; LP.Character.Humanoid.Health = 1e12 end)
    cB("Gms", "Games >", UDim2.new(0.07,0,0.65,0), MF, Color3.fromRGB(0,120,0)).MouseButton1Click:Connect(function() GP.Visible = true end)
    cB("Ex", "Close", UDim2.new(0.07,0,0.82,0), MF, Color3.fromRGB(120,0,0)).MouseButton1Click:Connect(function() MiniGui:Destroy() end)
    Instance.new("TextLabel", GP).Size = UDim2.new(1,0,0,30); GP:FindFirstChildOfClass("TextLabel").Text = "Game Scripts"; GP:FindFirstChildOfClass("TextLabel").BackgroundColor3 = Color3.fromRGB(0,100,150)
    cB("Inv", "Invisible", UDim2.new(0.07,0,0.12,0), GP).MouseButton1Click:Connect(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Invisible%20Gui'))() end)
    cB("Pz", "Pizza Place", UDim2.new(0.07,0,0.25,0), GP).MouseButton1Click:Connect(function() loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/blueEa1532/thechosenone/refs/heads/main/trollpizzagui"))() end)
    cB("M2", "MM2 Script", UDim2.new(0.07,0,0.38,0), GP).MouseButton1Click:Connect(function() loadstring(game:HttpGet('https://raw.smokingscripts.org/vertex.lua'))() end)
    cB("TP", "TP Player", UDim2.new(0.07,0,0.51,0), GP).MouseButton1Click:Connect(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Telxr/Teleportica/refs/heads/main/Telepo"))() end)
    cB("Fl", "Fling", UDim2.new(0.07,0,0.64,0), GP).MouseButton1Click:Connect(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))() end)
    cB("Bk", "< Back", UDim2.new(0.07,0,0.85,0), GP).MouseButton1Click:Connect(function() GP.Visible = false end)
end)
addCmd("Tank", function() LP.Character.Humanoid.MaxHealth = 100000; LP.Character.Humanoid.Health = 100000 end)
addCmd("Nuke", function() _G.target = "others"; TBox.Text = "Target: others" end)
addCmd("Master", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpyV2/master/simple-spy-v3.lua"))() end)
addCmd("Simple Spy", function() loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))() end)
addCmd("Script Searcher", function() loadstring(game:HttpGet("https://pastefy.app/cIrUcSTO/raw"))() end)
addCmd("Change BG", function() 
    Main.BackgroundColor3 = Color3.fromRGB(math.random(0,30), math.random(0,30), math.random(0,30))
    SyncAccent(Color3.fromHSV(math.random(), 0.8, 1))
end)

-- [[ TASKBAR CONTROLS ]]
SaveBtn.MouseButton1Click:Connect(function() SaveConfig() logTerminal("CONFIG SAVED", true) end)
ResetBtn.MouseButton1Click:Connect(function()
    _G.Positions = {}
    Grid.Enabled = true
    task.wait(0.1)
    Grid.Enabled = false
    for _, btn in pairs(UI_Registry.Buttons) do _G.Positions[btn.Name] = {btn.Position.X.Offset, btn.Position.Y.Offset} end
    SaveConfig()
    logTerminal("UI RESET", true)
end)

BuildBtn.MouseButton1Click:Connect(function() 
    _G.buildMode = not _G.buildMode
    BuildBtn.TextColor3 = _G.buildMode and Color3.new(1,1,0) or Color3.new(1,1,1)
    
    if _G.buildMode then
        -- Freeze items where they are currently in the grid
        for _, btn in pairs(UI_Registry.Buttons) do
            local absPos = btn.AbsolutePosition - CmdPage.AbsolutePosition
            btn.Position = UDim2.new(0, absPos.X, 0, absPos.Y + CmdPage.CanvasPosition.Y)
        end
        Grid.Enabled = false
    else
        Grid.Enabled = true
    end
end)

MainToggle.MouseButton1Click:Connect(function() 
    Main.Visible = not Main.Visible
    MainToggle.Text = Main.Visible and "Close" or "Open" 
end)

TermInput.FocusLost:Connect(function(enter)
    if enter then
        local cmd = TermInput.Text:lower()
        TermInput.Text = ""
        if CommandLogic[cmd] then local s, e = pcall(CommandLogic[cmd]) logTerminal(cmd:upper(), s) else logTerminal(cmd:upper(), false) end
    end
end)

-- [[ STARTUP ]]
LoadConfig()
local Start = Instance.new("Frame", ScreenGui); Start.Size = UDim2.new(1,0,1,0); Start.BackgroundColor3 = Color3.new(0,0,0); Start.ZIndex = 100
local Welcome = Instance.new("TextLabel", Start); Welcome.Size = UDim2.new(1,0,0.3,0); Welcome.BackgroundTransparency = 1; Welcome.Text = "ULTIMATE TROLL EM V3.01"; Welcome.TextColor3 = Color3.fromRGB(_G.r,_G.g,_G.b); Welcome.Font = "Code"; Welcome.TextSize = 35; Welcome.ZIndex = 101
table.insert(UI_Registry.Accents, Welcome)

local function b(n, sc, xOffset)
    local btn = Instance.new("TextButton", Start); btn.Size = UDim2.new(0,160,0,50); btn.Position = UDim2.new(0.5,xOffset,0.6,0); btn.AnchorPoint = Vector2.new(0.5,0.5); btn.Text = n; btn.ZIndex = 101; btn.Font = "Code"; btn.TextSize = 18; btn.BackgroundColor3 = Color3.fromRGB(_G.r,_G.g,_G.b)
    btn.MouseButton1Click:Connect(function() UIScale.Scale = sc; Start:Destroy(); Main.Visible = true; Taskbar.Visible = true end)
end
b("PC", 1, -100); b("Mobile", 0.7, 100)

RunService.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        if _G.noclip then for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
        if _G.flying then LP.Character.HumanoidRootPart.Velocity = Camera.CFrame.LookVector * _G.flySpeed end
        if _G.predator then local t = GetTargets()[1]; if t and t.Character then LP.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,5) end end
    end
end)

UIS.JumpRequest:Connect(function() if _G.infJump and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid:ChangeState("Jumping") end end)
