-- [[ ULTIMATE TROLL EM INTERMEDIATE I - REFINED V3 ]]
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "ULTIMATE_troll_em_INTERMEDIATE_I"
ScreenGui.ResetOnSpawn = false

-- [[ GLOBAL STATE ]]
local _G = {
    r = 25, g = 150, b = 255, -- Default Accent
    opacity = 0.8, flySpeed = 50,
    flying = false, infJump = false, noclip = false, predator = false,
    freezeActive = false, esp = false, sawnick = false, ghoul = false, tank = false, jetpack = false,
    target = "s", currentEditingTile = nil,
    mainSize = UDim2.new(0, 650, 0, 500)
}

-- [[ TARGETING ENGINE ]]
local function GetTargets(override)
    local text = (override or _G.target or "s"):lower()
    local victims = {}
    if text == "all" then return Players:GetPlayers()
    elseif text == "others" then for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(victims, p) end end
    elseif text == "random" then
        local others = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LP then table.insert(others, p) end end
        if #others > 0 then table.insert(victims, others[math.random(1, #others)]) end
    elseif text == "s" or text == "" or text == "me" then return {LP}
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #text) == text or p.DisplayName:lower():sub(1, #text) == text then table.insert(victims, p) end
        end
    end
    return victims
end

-- [[ MAIN FRAME (Transparent) ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = _G.mainSize; Main.Position = UDim2.new(0.5, -325, 0.5, -250)
Main.BackgroundTransparency = 1; Main.BorderSizePixel = 0; Main.Visible = false
local UIScale = Instance.new("UIScale", Main)

-- [[ TASKBAR & TOGGLE ]]
local Taskbar = Instance.new("Frame", ScreenGui)
Taskbar.Size = UDim2.new(1, 0, 0, 45); Taskbar.Position = UDim2.new(0, 0, 1, -45)
Taskbar.BackgroundColor3 = Color3.new(0, 0, 0); Taskbar.BackgroundTransparency = 0.6; Taskbar.BorderSizePixel = 0
Taskbar.Visible = false

local MainToggle = Instance.new("TextButton", Taskbar)
MainToggle.Size = UDim2.new(0, 150, 1, 0); MainToggle.Position = UDim2.new(1, -150, 0, 0)
MainToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30); MainToggle.BackgroundTransparency = 0.4
MainToggle.TextColor3 = Color3.fromRGB(0, 255, 150); MainToggle.Font = "SourceSansBold"; MainToggle.TextSize = 16
MainToggle.Text = "close troll em"; MainToggle.BorderSizePixel = 0
MainToggle.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    MainToggle.Text = Main.Visible and "close troll em" or "open troll em"
end)

local TermInput = Instance.new("TextBox", Taskbar)
TermInput.Size = UDim2.new(0.4, 0, 0.7, 0); TermInput.Position = UDim2.new(0.3, 0, 0.15, 0)
TermInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20); TermInput.BackgroundTransparency = 0.4
TermInput.TextColor3 = Color3.new(0, 1, 0); TermInput.PlaceholderText = "Type command here... (type 'metro' to return)"
TermInput.Font = "Code"; TermInput.TextSize = 14; TermInput.BorderSizePixel = 0

-- [[ TARGET BAR ]]
local TargetBar = Instance.new("Frame", Main)
TargetBar.Size = UDim2.new(1, -20, 0, 30); TargetBar.Position = UDim2.new(0, 10, 1, -40)
TargetBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10); TargetBar.BackgroundTransparency = 0.5; TargetBar.BorderSizePixel = 0
local TargetInput = Instance.new("TextBox", TargetBar)
TargetInput.Size = UDim2.new(1, -70, 1, 0); TargetInput.Position = UDim2.new(0, 65, 0, 0)
TargetInput.Text = _G.target; TargetInput.TextColor3 = Color3.new(1, 1, 1); TargetInput.BackgroundTransparency = 1
TargetInput.TextXAlignment = "Left"; TargetInput.ClearTextOnFocus = false
TargetInput.FocusLost:Connect(function() _G.target = TargetInput.Text end)

local TargetLabel = Instance.new("TextLabel", TargetBar)
TargetLabel.Size = UDim2.new(0, 60, 1, 0); TargetLabel.Text = " TARGET:"
TargetLabel.TextColor3 = Color3.new(0, 1, 0); TargetLabel.BackgroundTransparency = 1
TargetLabel.Font = "SourceSansBold"; TargetLabel.TextSize = 14; TargetLabel.TextXAlignment = "Left"

-- [[ COLOR POPUP ]]
local Popup = Instance.new("Frame", ScreenGui)
Popup.Size = UDim2.new(0, 140, 0, 70); Popup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Popup.BorderSizePixel = 0; Popup.Visible = false; Popup.ZIndex = 100

local TransBtn = Instance.new("TextButton", Popup)
TransBtn.Size = UDim2.new(1, 0, 0.5, 0); TransBtn.Text = "Translucent"
TransBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); TransBtn.TextColor3 = Color3.new(1,1,1); TransBtn.BorderSizePixel = 0

local AccentBtn = Instance.new("TextButton", Popup)
AccentBtn.Size = UDim2.new(1, 0, 0.5, 0); AccentBtn.Position = UDim2.new(0, 0, 0.5, 0)
AccentBtn.Text = "Accent Color"; AccentBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AccentBtn.TextColor3 = Color3.new(1,1,1); AccentBtn.BorderSizePixel = 0

local function showPopup(tile, pos)
    _G.currentEditingTile = tile
    Popup.Position = UDim2.new(0, pos.X, 0, pos.Y)
    Popup.Visible = true
end

TransBtn.MouseButton1Click:Connect(function()
    if _G.currentEditingTile then
        _G.currentEditingTile.BackgroundColor3 = Color3.new(0, 0, 0)
        _G.currentEditingTile.BackgroundTransparency = 0.6
    end
    Popup.Visible = false
end)

AccentBtn.MouseButton1Click:Connect(function()
    if _G.currentEditingTile then
        _G.currentEditingTile.BackgroundColor3 = Color3.fromRGB(_G.r, _G.g, _G.b)
        _G.currentEditingTile.BackgroundTransparency = 0
    end
    Popup.Visible = false
end)

UIS.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        task.delay(0.1, function() Popup.Visible = false end)
    end
end)

-- [[ PAGES ]]
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, 0, 1, -50); Content.BackgroundTransparency = 1

local Pages = { Cmd = Instance.new("Frame", Content), Terminal = Instance.new("Frame", Content) }

local TermLog = Instance.new("ScrollingFrame", Pages.Terminal)
TermLog.Size = UDim2.new(1, 0, 1, 0); TermLog.BackgroundTransparency = 1
TermLog.BorderSizePixel = 0; TermLog.CanvasSize = UDim2.new(0, 0, 10, 0); TermLog.ScrollBarThickness = 4
local LogLayout = Instance.new("UIListLayout", TermLog)
LogLayout.VerticalAlignment = "Bottom"; LogLayout.Padding = UDim.new(0, 2)

for n, p in pairs(Pages) do
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1
    p.Visible = (n == "Cmd")
end

-- [[ COMMAND ENGINE ]]
local Commands = {}
local tileCount = 0

local function logTerminal(msg, success)
    local l = Instance.new("TextLabel", TermLog)
    l.Size = UDim2.new(1, 0, 0, 20); l.BackgroundTransparency = 1
    l.Text = "> " .. msg:upper() .. (success and " : SUCCESS" or " : FAILED")
    l.TextColor3 = success and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    l.Font = "Code"; l.TextSize = 14; l.TextXAlignment = "Left"
end

local function addCmd(n, cb)
    local clean = n:lower():gsub(" ", "")
    Commands[clean] = cb
    
    local tileSize = 96
    local padding = 12
    local columns = 6
    
    local t = Instance.new("TextButton", Pages.Cmd)
    t.Size = UDim2.new(0, tileSize, 0, tileSize)
    t.Position = UDim2.new(0, (tileCount % columns) * (tileSize + padding), 0, math.floor(tileCount / columns) * (tileSize + padding))
    t.Text = n:upper(); t.BackgroundColor3 = Color3.fromRGB(_G.r, _G.g, _G.b)
    t.TextColor3 = Color3.new(1,1,1); t.BorderSizePixel = 0; t.Font = "SourceSansBold"; t.TextWrapped = true
    
    tileCount = tileCount + 1
    
    local drag, dStart, sPos
    t.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            showPopup(t, UIS:GetMouseLocation())
        elseif i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; dStart = i.Position; sPos = t.Position
            local currentStart = dStart
            task.delay(0.5, function()
                if drag and (i.Position - currentStart).Magnitude < 5 then
                    showPopup(t, UIS:GetMouseLocation()); drag = false 
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i) 
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then 
            t.Position = UDim2.new(0, sPos.X.Offset + (i.Position - dStart).X, 0, sPos.Y.Offset + (i.Position - dStart).Y) 
        end 
    end)
    UIS.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end 
    end)
    t.MouseButton1Click:Connect(function() local s, e = pcall(cb); logTerminal(n, s) end)
end

-- [[ ALL COMMANDS INCLUDED ]]
addCmd("Fly", function() _G.flying = not _G.flying end)
addCmd("Noclip", function() _G.noclip = not _G.noclip end)
addCmd("InfJump", function() _G.infJump = not _G.infJump end)
addCmd("Sawnick", function() _G.sawnick = not _G.sawnick; if LP.Character then LP.Character.Humanoid.WalkSpeed = _G.sawnick and 500 or 16 end end)
addCmd("TP", function() local t = GetTargets(); if #t > 0 and t[1].Character then LP.Character.HumanoidRootPart.CFrame = t[1].Character.HumanoidRootPart.CFrame end end)
addCmd("Fling", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))() end)
addCmd("Orbit", function() _G.predator = not _G.predator end)
addCmd("Invisible", function() loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))() end)
addCmd("ESP", function() _G.esp = not _G.esp; for _,p in pairs(Players:GetPlayers()) do if p.Character then if _G.esp then local h = Instance.new("Highlight", p.Character) else if p.Character:FindFirstChild("Highlight") then p.Character.Highlight:Destroy() end end end end end)
addCmd("InfYield", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
addCmd("Dex", function() loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Dex%20Explorer.lua"))() end)
addCmd("Jetpack", function() _G.jetpack = not _G.jetpack; _G.flying = _G.jetpack; _G.flySpeed = _G.jetpack and 100 or 50 end)
addCmd("Ghoul", function() _G.ghoul = not _G.ghoul; if LP.Character then for _,v in pairs(LP.Character:GetChildren()) do if v:IsA("BasePart") then v.Transparency = _G.ghoul and 0.5 or 0 end end end end)
addCmd("Tank", function() _G.tank = not _G.tank; if LP.Character then LP.Character.Humanoid.MaxHealth = _G.tank and 100000 or 100; LP.Character.Humanoid.Health = LP.Character.Humanoid.MaxHealth end end)
addCmd("Nuke", function() _G.target = "others"; _G.freezeActive = true end)
addCmd("Master", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpyV2/master/simple-spy-v3.lua"))() end)
addCmd("Simple Spy", function() loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))() end)
addCmd("BG Color", function() 
    _G.r, _G.g, _G.b = math.random(0,255), math.random(0,255), math.random(0,255)
    for _, child in pairs(Pages.Cmd:GetChildren()) do
        if child:IsA("TextButton") and child.BackgroundTransparency == 0 then
            child.BackgroundColor3 = Color3.fromRGB(_G.r, _G.g, _G.b)
        end
    end
end)
addCmd("Script Searcher", function() loadstring(game:HttpGet("https://pastefy.app/cIrUcSTO/raw"))() end)
addCmd("Terminal", function() Pages.Cmd.Visible = false; Pages.Terminal.Visible = true end)

TermInput.FocusLost:Connect(function(e)
    if not e then return end
    local txt = TermInput.Text:lower(); TermInput.Text = ""
    if txt == "metro" then Pages.Terminal.Visible = false; Pages.Cmd.Visible = true; return end
    
    if not Pages.Terminal.Visible then
        Pages.Cmd.Visible = false; Pages.Terminal.Visible = true
    end
    if Commands[txt] then local success, _ = pcall(Commands[txt]); logTerminal(txt, success) else logTerminal(txt, false) end
end)

-- [[ DEVICE SELECTOR ]]
local Start = Instance.new("Frame", ScreenGui)
Start.Size = UDim2.new(0, 250, 0, 140); Start.Position = UDim2.new(0.5, -125, 0.5, -70); Start.BackgroundColor3 = Color3.fromRGB(20,20,20)
local StartLabel = Instance.new("TextLabel", Start); StartLabel.Size = UDim2.new(1,0,0,40); StartLabel.Text = "SELECT DEVICE"; StartLabel.TextColor3 = Color3.new(1,1,1); StartLabel.BackgroundTransparency = 1

local function setupDev(n, sc, y)
    local b = Instance.new("TextButton", Start)
    b.Size = UDim2.new(0.8,0,0,30); b.Position = UDim2.new(0.1,0,0,y); b.Text = n
    b.BackgroundColor3 = Color3.fromRGB(40,40,40); b.TextColor3 = Color3.new(1,1,1); b.BorderSizePixel = 0
    b.MouseButton1Click:Connect(function() 
        UIScale.Scale = sc; Start:Destroy(); Main.Visible = true; Taskbar.Visible = true 
    end)
end
setupDev("PC", 1.0, 50); setupDev("MOBILE", 0.6, 90)

-- [[ LOOPS ]]
RunService.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        if _G.noclip then for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
        if _G.flying then LP.Character.HumanoidRootPart.Velocity = Camera.CFrame.LookVector * _G.flySpeed end
        if _G.predator then local t = GetTargets()[1] if t and t.Character then LP.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,5) end end
    end
end)
UIS.JumpRequest:Connect(function() if _G.infJump and LP.Character then LP.Character.Humanoid:ChangeState("Jumping") end end)
