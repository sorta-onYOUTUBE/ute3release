-- [[ TROLL EM 1.1 - COMPACT GRID ]]

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "Trollem11_Mini"
ScreenGui.ResetOnSpawn = false

local function createMenu(titleText)
    local Frame = Instance.new("Frame")
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.Position = UDim2.new(0.35, 0, 0.35, 0)
    Frame.Size = UDim2.new(0, 320, 0, 200) -- Significantly smaller
    Frame.Active = true
    Frame.Draggable = true
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 25) -- Thinner title bar
    Title.BackgroundColor3 = Color3.fromRGB(90, 0, 190)
    Title.Text = titleText
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 14
    Title.Parent = Frame

    local Container = Instance.new("Frame")
    Container.Position = UDim2.new(0, 5, 0, 30)
    Container.Size = UDim2.new(1, -10, 1, -35)
    Container.BackgroundTransparency = 1
    Container.Parent = Frame

    local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = UDim2.new(0, 95, 0, 45) -- Smaller buttons
    Grid.CellPadding = UDim2.new(0, 8, 0, 8)
    Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Grid.Parent = Container

    return Frame, Container
end

local MainFrame, MainContainer = createMenu("TROLL EM 1.1")
local GameFrame, GameContainer = createMenu("GAME SCRIPTS")
GameFrame.Visible = false

local function addElement(class, text, parent, color)
    local obj = Instance.new(class)
    obj.BackgroundColor3 = color or Color3.fromRGB(40, 40, 40)
    obj.TextColor3 = Color3.new(1, 1, 1)
    obj.BorderSizePixel = 0
    obj.Font = Enum.Font.SourceSans
    obj.TextSize = 12 -- Smaller font
    if class == "TextBox" then
        obj.PlaceholderText = text
        obj.Text = ""
    else
        obj.Text = text
    end
    obj.Parent = parent
    return obj
end

-- Main Buttons
local IY = addElement("TextButton", "Inf Yield", MainContainer)
local Dex = addElement("TextButton", "Dex", MainContainer)
local HP = addElement("TextButton", "1T HP", MainContainer)
local FastMode = addElement("TextButton", "Fast Mode", MainContainer, Color3.fromRGB(130, 70, 0))
local SpeedBox = addElement("TextBox", "Speed", MainContainer, Color3.fromRGB(0, 60, 120))
local JumpBox = addElement("TextBox", "Jump", MainContainer, Color3.fromRGB(0, 60, 120))
local OpenGames = addElement("TextButton", "GAMES >", MainContainer, Color3.fromRGB(0, 100, 50))
local Exit = addElement("TextButton", "EXIT", MainContainer, Color3.fromRGB(100, 0, 0))

-- Game Buttons
local UserBox = addElement("TextBox", "User Name", GameContainer)
local TPBtn = addElement("TextButton", "TP to Him", GameContainer, Color3.fromRGB(0, 80, 160))
local Invis = addElement("TextButton", "Invis", GameContainer)
local Pizza = addElement("TextButton", "Pizza", GameContainer)
local MM2 = addElement("TextButton", "MM2", GameContainer)
local Fling = addElement("TextButton", "Fling", GameContainer)
local BackBtn = addElement("TextButton", "< BACK", GameContainer, Color3.fromRGB(60, 60, 60))

-- Logic
IY.MouseButton1Click:Connect(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
Dex.MouseButton1Click:Connect(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))() end)
HP.MouseButton1Click:Connect(function() 
    local h = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.MaxHealth = 1e12 h.Health = 1e12 end 
end)
FastMode.MouseButton1Click:Connect(function()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = "Plastic" end
        if v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end
    end
end)

SpeedBox.FocusLost:Connect(function() game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = tonumber(SpeedBox.Text) or 16 end)
JumpBox.FocusLost:Connect(function() game.Players.LocalPlayer.Character.Humanoid.JumpPower = tonumber(JumpBox.Text) or 50 end)
OpenGames.MouseButton1Click:Connect(function() GameFrame.Visible = true MainFrame.Visible = false end)
BackBtn.MouseButton1Click:Connect(function() GameFrame.Visible = false MainFrame.Visible = true end)
Exit.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

TPBtn.MouseButton1Click:Connect(function()
    local target = game:GetService("Players"):FindFirstChild(UserBox.Text)
    if target and target.Character then
        game.Players.LocalPlayer.Character:MoveTo(target.Character.HumanoidRootPart.Position)
    end
end)

Invis.MouseButton1Click:Connect(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Invisible%20Gui'))() end)
Pizza.MouseButton1Click:Connect(function() loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/blueEa1532/thechosenone/refs/heads/main/trollpizzagui"))() end)
MM2.MouseButton1Click:Connect(function() loadstring(game:HttpGet('https://raw.smokingscripts.org/vertex.lua'))() end)
Fling.MouseButton1Click:Connect(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))() end)
