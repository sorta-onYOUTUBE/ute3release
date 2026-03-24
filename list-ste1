-- Troll em 1.0 GUI (Updated)
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local IYButton = Instance.new("TextButton")
local DexButton = Instance.new("TextButton")
local HPButton = Instance.new("TextButton")
local OpenGamesButton = Instance.new("TextButton")
local ExitButton = Instance.new("TextButton")

local GamePanel = Instance.new("Frame")
local GameTitle = Instance.new("TextLabel")
local InvisibleButton = Instance.new("TextButton")
local PizzaButton = Instance.new("TextButton")
local MM2Button = Instance.new("TextButton")
local TPButton = Instance.new("TextButton")
local FlingButton = Instance.new("TextButton")
local CloseGamesButton = Instance.new("TextButton")

-- Properties
ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "Trollem10"
ScreenGui.ResetOnSpawn = false

-- Main Frame Setup
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Troll em 1.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundColor3 = Color3.fromRGB(60, 0, 150)

-- Core Buttons
local function createBtn(name, text, pos, parent, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = text
    btn.Position = pos
    btn.Size = UDim2.new(0.85, 0, 0, 35)
    btn.Parent = parent
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1,1,1)
    return btn
end

IYButton = createBtn("IY", "Infinite Yield", UDim2.new(0.07, 0, 0.15, 0), MainFrame)
IYButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

DexButton = createBtn("Dex", "Dex Explorer", UDim2.new(0.07, 0, 0.30, 0), MainFrame)
DexButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))()
end)

HPButton = createBtn("HP", "God HP (Local)", UDim2.new(0.07, 0, 0.45, 0), MainFrame)
HPButton.MouseButton1Click:Connect(function()
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.MaxHealth = 1000000000000
        char.Humanoid.Health = 1000000000000
    end
end)

OpenGamesButton = createBtn("Games", "Game Scripts >", UDim2.new(0.07, 0, 0.65, 0), MainFrame, Color3.fromRGB(0, 120, 0))
OpenGamesButton.MouseButton1Click:Connect(function() GamePanel.Visible = true end)

ExitButton = createBtn("Exit", "Close GUI", UDim2.new(0.07, 0, 0.82, 0), MainFrame, Color3.fromRGB(120, 0, 0))
ExitButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Sub-Panel Setup
GamePanel.Parent = ScreenGui
GamePanel.Size = UDim2.new(0, 220, 0, 320)
GamePanel.Position = UDim2.new(0.2, 0, 0.3, 0)
GamePanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
GamePanel.Visible = false
GamePanel.Active = true
GamePanel.Draggable = true

GameTitle.Parent = GamePanel
GameTitle.Size = UDim2.new(1, 0, 0, 30)
GameTitle.Text = "Game & Troll Scripts"
GameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
GameTitle.BackgroundColor3 = Color3.fromRGB(0, 100, 150)

-- Game Scripts Section
InvisibleButton = createBtn("Invis", "Invisible", UDim2.new(0.07, 0, 0.12, 0), GamePanel)
InvisibleButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Invisible%20Gui'))()
end)

PizzaButton = createBtn("Pizza", "Work Pizza Place", UDim2.new(0.07, 0, 0.25, 0), GamePanel)
PizzaButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/blueEa1532/thechosenone/refs/heads/main/trollpizzagui"))()
end)

MM2Button = createBtn("MM2", "MM2 Script", UDim2.new(0.07, 0, 0.38, 0), GamePanel)
MM2Button.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet('https://raw.smokingscripts.org/vertex.lua'))()
end)

TPButton = createBtn("TP", "Teleport to Player", UDim2.new(0.07, 0, 0.51, 0), GamePanel)
TPButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Telxr/Teleportica/refs/heads/main/Telepo"))()
end)

FlingButton = createBtn("Fling", "Ultimate Fling", UDim2.new(0.07, 0, 0.64, 0), GamePanel)
FlingButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))()
end)

CloseGamesButton = createBtn("Back", "< Back", UDim2.new(0.07, 0, 0.85, 0), GamePanel, Color3.fromRGB(80, 80, 80))
CloseGamesButton.MouseButton1Click:Connect(function() GamePanel.Visible = false end)
