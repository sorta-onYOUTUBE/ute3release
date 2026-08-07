-- [[ ULTIMATE troll em 2.0 - SETTINGS BACK BUTTON UPDATE ]]
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "ULTIMATE_troll_em_2.0"
ScreenGui.ResetOnSpawn = false

-- [[ GLOBAL STATE ]]
local _G = { 
    r = 25, g = 25, b = 25, opacity = 0.8, flySpeed = 50,
    flying = false, infJump = false, noclip = false, predator = false,
    minimized = false, target = "", CurrentTile = nil, grid = 64
}

local OriginalSettings = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness, GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd
}

-- [[ DRAG HELPER ]]
local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- [[ 1. MAIN UI STRUCTURE ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 600, 0, 480); Main.Position = UDim2.new(0.5, -300, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(_G.r, _G.g, _G.b); Main.BorderSizePixel = 0; Main.Visible = false
Main.BackgroundTransparency = 1 - _G.opacity

local Content = Instance.new("Frame", Main); Content.Size = UDim2.new(1, 0, 1, -35); Content.Position = UDim2.new(0, 0, 0, 0); Content.BackgroundTransparency = 1
local Pages = { Cmd = Instance.new("ScrollingFrame", Content), Set = Instance.new("ScrollingFrame", Content), Edit = Instance.new("Frame", Content) }
for n, p in pairs(Pages) do 
    p.Size = UDim2.new(1, -20, 1, -20); p.Position = UDim2.new(0, 10, 0, 10); p.BackgroundTransparency = 1
    if p:IsA("ScrollingFrame") then p.CanvasSize = UDim2.new(0,0,5,0) end
    p.Visible = (n == "Cmd") 
end

-- Bottom Control Bar
local BottomBar = Instance.new("Frame", Main); BottomBar.Size = UDim2.new(1, 0, 0, 35); BottomBar.Position = UDim2.new(0, 0, 1, -35); BottomBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
local TitleLabel = Instance.new("TextLabel", BottomBar); TitleLabel.Size = UDim2.new(0, 250, 1, 0); TitleLabel.Position = UDim2.new(0, 10, 0, 0); TitleLabel.Text = "ULTIMATE TROLL EM 2.0"; TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 150); TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.TextSize = 16; TitleLabel.BackgroundTransparency = 1; TitleLabel.TextXAlignment = "Left"

local CloseBtn = Instance.new("TextButton", BottomBar); CloseBtn.Size = UDim2.new(0, 35, 0, 35); CloseBtn.Position = UDim2.new(1, -35, 0, 0); CloseBtn.Text = "X"; CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.BorderSizePixel = 0
local MinBtn = Instance.new("TextButton", BottomBar); MinBtn.Size = UDim2.new(0, 35, 0, 35); MinBtn.Position = UDim2.new(1, -70, 0, 0); MinBtn.Text = "-"; MinBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 0); MinBtn.TextColor3 = Color3.new(1,1,1); MinBtn.BorderSizePixel = 0

makeDraggable(Main, BottomBar)

-- [[ 2. TILE CUSTOMIZATION PANEL (EDIT PAGE) ]]
local EditPage = Pages.Edit
local tempSize = UDim2.new(0, 120, 0, 120)

local function createEditInput(label, yPos, default)
    local l = Instance.new("TextLabel", EditPage); l.Size = UDim2.new(0, 60, 0, 30); l.Position = UDim2.new(0, 10, 0, yPos); l.Text = label..":"; l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1; l.Font = Enum.Font.SourceSansBold; l.TextXAlignment = "Left"
    local i = Instance.new("TextBox", EditPage); i.Name = label.."_Input"; i.Size = UDim2.new(0, 80, 0, 30); i.Position = UDim2.new(0, 80, 0, yPos); i.Text = default; i.BackgroundColor3 = Color3.fromRGB(40,40,40); i.TextColor3 = Color3.new(1,1,1)
    return i
end

local rIn = createEditInput("R", 10, "255"); local gIn = createEditInput("G", 50, "255"); local bIn = createEditInput("B", 90, "255"); local opIn = createEditInput("Opacity", 130, "1.0")

local function createSizeOption(txt, size, y)
    local b = Instance.new("TextButton", EditPage); b.Size = UDim2.new(0, 150, 0, 35); b.Position = UDim2.new(0, 200, 0, y); b.Text = txt; b.BackgroundColor3 = Color3.fromRGB(60,60,60); b.TextColor3 = Color3.new(1,1,1)
    b.MouseButton1Click:Connect(function() tempSize = size end)
end
createSizeOption("SMALL", UDim2.new(0, 64, 0, 64), 10); createSizeOption("MEDIUM", UDim2.new(0, 128, 0, 128), 50); createSizeOption("WIDE", UDim2.new(0, 256, 0, 128), 90); createSizeOption("LARGE", UDim2.new(0, 256, 0, 256), 130)

local ApplyBtn = Instance.new("TextButton", EditPage); ApplyBtn.Size = UDim2.new(0, 130, 0, 50); ApplyBtn.Position = UDim2.new(0, 10, 0.75, 0); ApplyBtn.Text = "APPLY"; ApplyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80); ApplyBtn.TextColor3 = Color3.new(1,1,1)
local ResetBtn = Instance.new("TextButton", EditPage); ResetBtn.Size = UDim2.new(0, 130, 0, 50); ResetBtn.Position = UDim2.new(0, 150, 0.75, 0); ResetBtn.Text = "RESET"; ResetBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0); ResetBtn.TextColor3 = Color3.new(1,1,1)
local BackBtnEdit = Instance.new("TextButton", EditPage); BackBtnEdit.Size = UDim2.new(0, 130, 0, 50); BackBtnEdit.Position = UDim2.new(0, 290, 0.75, 0); BackBtnEdit.Text = "BACK"; BackBtnEdit.BackgroundColor3 = Color3.fromRGB(200, 50, 50); BackBtnEdit.TextColor3 = Color3.new(1,1,1)

ApplyBtn.MouseButton1Click:Connect(function()
    if _G.CurrentTile then
        _G.CurrentTile.BackgroundColor3 = Color3.fromRGB(tonumber(rIn.Text) or 255, tonumber(gIn.Text) or 255, tonumber(bIn.Text) or 255)
        _G.CurrentTile.BackgroundTransparency = 1 - (tonumber(opIn.Text) or 1)
        _G.CurrentTile.Size = tempSize
    end
end)

ResetBtn.MouseButton1Click:Connect(function()
    if _G.CurrentTile then
        _G.CurrentTile.BackgroundColor3 = Color3.fromRGB(math.random(50,200), math.random(50,200), math.random(50,200))
        _G.CurrentTile.BackgroundTransparency = 0; _G.CurrentTile.Size = UDim2.new(0, 120, 0, 120)
        local c = _G.CurrentTile.BackgroundColor3
        rIn.Text = tostring(math.floor(c.R*255)); gIn.Text = tostring(math.floor(c.G*255)); bIn.Text = tostring(math.floor(c.B*255)); opIn.Text = "1.0"
    end
end)

BackBtnEdit.MouseButton1Click:Connect(function() Pages.Edit.Visible = false; Pages.Cmd.Visible = true end)

-- [[ 3. COMMAND ENGINE ]]
local function makeTileDraggable(tile)
    local dragging, dragStart, startPos
    tile.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true; dragStart = input.Position; startPos = tile.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            tile.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
             dragging = false; local snapX = math.round(tile.Position.X.Offset / _G.grid) * _G.grid; local snapY = math.round(tile.Position.Y.Offset / _G.grid) * _G.grid; tile.Position = UDim2.new(0, snapX, 0, snapY)
        end
    end)
end

local tileCount = 0
local function addCmd(n, cb)
    local t = Instance.new("TextButton", Pages.Cmd); t.Size = UDim2.new(0, 120, 0, 120); t.Position = UDim2.new(0, (tileCount % 4) * 128, 0, math.floor(tileCount / 4) * 128)
    t.Text = n:upper(); t.BackgroundColor3 = Color3.fromRGB(math.random(50,150),math.random(50,150),math.random(50,150)); t.BorderSizePixel = 0; t.TextColor3 = Color3.new(1,1,1); t.Font = Enum.Font.SourceSansBold; t.TextSize = 12
    tileCount = tileCount + 1; makeTileDraggable(t)
    
    local function openEdit() 
        _G.CurrentTile = t; Pages.Cmd.Visible = false; Pages.Set.Visible = false; Pages.Edit.Visible = true
        local c = t.BackgroundColor3
        rIn.Text = tostring(math.floor(c.R*255)); gIn.Text = tostring(math.floor(c.G*255)); bIn.Text = tostring(math.floor(c.B*255)); opIn.Text = tostring(1-t.BackgroundTransparency)
    end
    
    t.MouseButton2Click:Connect(openEdit)
    local holding = false
    t.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then holding = true; task.delay(0.6, function() if holding then openEdit() end end) end end)
    t.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then holding = false end end)
    t.MouseButton1Click:Connect(function() if not Pages.Edit.Visible then cb() end end)
end

-- Commands
addCmd("Bird (Fly)", function() _G.flying = not _G.flying end)
addCmd("Ghost (Noclip)", function() _G.noclip = not _G.noclip end)
addCmd("Predator", function() _G.predator = not _G.predator end)
addCmd("Invisible", function() loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))() end)
addCmd("TP to Player", function() loadstring(game:HttpGet("https://pastebin.com/raw/AbDM2er1"))() end)
addCmd("Fling Player", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))() end)
addCmd("Inf Yield", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
addCmd("MM2 Troll", function() loadstring(game:HttpGet('https://raw.smokingscripts.org/vertex.lua'))() end)
addCmd("WAAPP Pizza", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/oShyyyyy/iris-jhub/main/WorkAtpizzaplace'))() end)
addCmd("Eagle Eye", function() _G.esp = not _G.esp; for _,p in pairs(Players:GetPlayers()) do if p.Character then if _G.esp then local h = Instance.new("Highlight", p.Character); h.FillColor = Color3.new(1,0,0) elseif p.Character:FindFirstChild("Highlight") then p.Character.Highlight:Destroy() end end end end)
addCmd("Sawnick", function() _G.sawnick = not _G.sawnick; LP.Character.Humanoid.WalkSpeed = _G.sawnick and 500 or 16 end)
addCmd("Kangaroo", function() _G.infJump = not _G.infJump end)
addCmd("Night Vision", function() Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.Brightness = 2; Lighting.FogEnd = 100000 end)
addCmd("Fast Mode", function() Lighting.GlobalShadows = false; for _, v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic elseif v:IsA("Decal") then v:Destroy() end end end)
addCmd("Restore Graphics", function() Lighting.Ambient = OriginalSettings.Ambient; Lighting.OutdoorAmbient = OriginalSettings.OutdoorAmbient; Lighting.Brightness = OriginalSettings.Brightness; Lighting.GlobalShadows = OriginalSettings.GlobalShadows; Lighting.FogEnd = OriginalSettings.FogEnd end)
addCmd("Settings", function() Pages.Cmd.Visible = false; Pages.Set.Visible = true; Pages.Edit.Visible = false end)

-- [[ 4. SETTINGS PAGE ]]
local SLayout = Instance.new("UIListLayout", Pages.Set); SLayout.Padding = UDim.new(0, 10)
local function addSet(txt, val, cb)
    local l = Instance.new("TextLabel", Pages.Set); l.Size = UDim2.new(1,0,0,20); l.Text = txt; l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1; l.TextXAlignment = "Left"
    local b = Instance.new("TextBox", Pages.Set); b.Size = UDim2.new(1,-10,0,30); b.BackgroundColor3 = Color3.fromRGB(40,40,40); b.TextColor3 = Color3.new(1,1,1); b.Text = tostring(_G[val])
    b.FocusLost:Connect(function() _G[val] = tonumber(b.Text) or b.Text; if cb then cb() end end)
end
local function updateMain() Main.BackgroundColor3 = Color3.fromRGB(_G.r, _G.g, _G.b); Main.BackgroundTransparency = 1 - _G.opacity end
addSet("RGB Red", "r", updateMain); addSet("RGB Green", "g", updateMain); addSet("RGB Blue", "b", updateMain); addSet("Opacity", "opacity", updateMain); addSet("Target", "target", nil)

-- Settings Back Button
local SetBackBtn = Instance.new("TextButton", Pages.Set)
SetBackBtn.Size = UDim2.new(1, -10, 0, 40)
SetBackBtn.Text = "BACK TO COMMANDS"
SetBackBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
SetBackBtn.TextColor3 = Color3.new(1,1,1); SetBackBtn.Font = Enum.Font.SourceSansBold
SetBackBtn.MouseButton1Click:Connect(function() Pages.Cmd.Visible = true; Pages.Set.Visible = false end)

-- [[ 5. LAUNCHER ]]
local Popup = Instance.new("Frame", ScreenGui); Popup.Size = UDim2.new(0, 320, 0, 260); Popup.Position = UDim2.new(0.5, -160, 0.5, -130); Popup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UIStroke", Popup).Color = Color3.fromRGB(0, 255, 150); Instance.new("UICorner", Popup)
local function launch(sc) local us = Instance.new("UIScale", ScreenGui); us.Scale = sc; Popup:Destroy(); Main.Visible = true end
local function makePopBtn(txt, y, clr, sc)
    local b = Instance.new("TextButton", Popup); b.Size = UDim2.new(0, 260, 0, 45); b.Position = UDim2.new(0.5, -130, 0, y); b.Text = txt; b.BackgroundColor3 = clr; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.SourceSansBold
    b.MouseButton1Click:Connect(function() launch(sc) end)
end
makePopBtn("MOBILE", 70, Color3.fromRGB(200, 50, 50), 0.6); makePopBtn("PC", 180, Color3.fromRGB(0, 120, 215), 1.0)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
MinBtn.MouseButton1Click:Connect(function() _G.minimized = not _G.minimized; Main:TweenSize(_G.minimized and UDim2.new(0, 600, 0, 35) or UDim2.new(0, 600, 0, 480), "Out", "Quad", 0.3, true) end)

-- Runtime
RunService.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        if _G.noclip then for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
        if _G.flying then LP.Character.HumanoidRootPart.Velocity = Camera.CFrame.LookVector * _G.flySpeed end
        if _G.predator and _G.target ~= "" then local t = Players:FindFirstChild(_G.target); if t and t.Character then LP.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3) end end
    end
end)
UIS.JumpRequest:Connect(function() if _G.infJump then LP.Character.Humanoid:ChangeState("Jumping") end end)
