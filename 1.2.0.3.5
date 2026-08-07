-- [[ Troll em 2.0.3.5.2026 - STREAMLINED EDITION ]]
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "Troll_em_2.0.3.5.2026"
ScreenGui.ResetOnSpawn = false

-- [[ GLOBAL STATE ]]
local _G = { 
    r = 25, g = 25, b = 25, opacity = 0.8,
    minimized = false, target = "", CurrentTile = nil, grid = 64
}

local OriginalSettings = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness, GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd
}

-- [[ DRAG HELPER ]]
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
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
local TitleLabel = Instance.new("TextLabel", BottomBar); TitleLabel.Size = UDim2.new(0, 250, 1, 0); TitleLabel.Position = UDim2.new(0, 10, 0, 0); TitleLabel.Text = "Troll em 2.0.3.5.2026"; TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 150); TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.TextSize = 16; TitleLabel.BackgroundTransparency = 1; TitleLabel.TextXAlignment = "Left"

local CloseBtn = Instance.new("TextButton", BottomBar); CloseBtn.Size = UDim2.new(0, 35, 0, 35); CloseBtn.Position = UDim2.new(1, -35, 0, 0); CloseBtn.Text = "X"; CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.BorderSizePixel = 0
local MinBtn = Instance.new("TextButton", BottomBar); MinBtn.Size = UDim2.new(0, 35, 0, 35); MinBtn.Position = UDim2.new(1, -70, 0, 0); MinBtn.Text = "-"; MinBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 0); MinBtn.TextColor3 = Color3.new(1,1,1); MinBtn.BorderSizePixel = 0

makeDraggable(Main, BottomBar)

-- [[ 2. TILE CUSTOMIZATION PANEL (EDIT PAGE) ]]
local EditPage = Pages.Edit
local tempSize = UDim2.new(0, 128, 0, 128)

local opLabel = Instance.new("TextLabel", EditPage); opLabel.Size = UDim2.new(0, 100, 0, 30); opLabel.Position = UDim2.new(0, 10, 0, 10); opLabel.Text = "Opacity (0-1):"; opLabel.TextColor3 = Color3.new(1,1,1); opLabel.BackgroundTransparency = 1; opLabel.Font = Enum.Font.SourceSansBold
local opIn = Instance.new("TextBox", EditPage); opIn.Size = UDim2.new(0, 100, 0, 30); opIn.Position = UDim2.new(0, 120, 0, 10); opIn.Text = "1.0"; opIn.BackgroundColor3 = Color3.fromRGB(40,40,40); opIn.TextColor3 = Color3.new(1,1,1)

local function createSizeOption(txt, size, y)
    local b = Instance.new("TextButton", EditPage); b.Size = UDim2.new(0, 150, 0, 40); b.Position = UDim2.new(0, 10, 0, y); b.Text = txt; b.BackgroundColor3 = Color3.fromRGB(60,60,60); b.TextColor3 = Color3.new(1,1,1)
    b.MouseButton1Click:Connect(function() tempSize = size end)
end
createSizeOption("MEDIUM (2x2)", UDim2.new(0, 128, 0, 128), 60); createSizeOption("WIDE (4x2)", UDim2.new(0, 256, 0, 128), 110)

local ApplyBtn = Instance.new("TextButton", EditPage); ApplyBtn.Size = UDim2.new(0, 130, 0, 50); ApplyBtn.Position = UDim2.new(0, 10, 0.75, 0); ApplyBtn.Text = "APPLY"; ApplyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80); ApplyBtn.TextColor3 = Color3.new(1,1,1)
local BackBtnEdit = Instance.new("TextButton", EditPage); BackBtnEdit.Size = UDim2.new(0, 130, 0, 50); BackBtnEdit.Position = UDim2.new(0, 150, 0.75, 0); BackBtnEdit.Text = "BACK"; BackBtnEdit.BackgroundColor3 = Color3.fromRGB(200, 50, 50); BackBtnEdit.TextColor3 = Color3.new(1,1,1)

ApplyBtn.MouseButton1Click:Connect(function()
    if _G.CurrentTile then
        _G.CurrentTile.BackgroundTransparency = 1 - (tonumber(opIn.Text) or 1)
        _G.CurrentTile.Size = tempSize
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
    local t = Instance.new("TextButton", Pages.Cmd); t.Size = UDim2.new(0, 128, 0, 128); t.Position = UDim2.new(0, (tileCount % 4) * 135, 0, math.floor(tileCount / 4) * 135)
    t.Text = n:upper(); t.BackgroundColor3 = Color3.fromRGB(math.random(40,80),math.random(40,80),math.random(40,80)); t.BorderSizePixel = 0; t.TextColor3 = Color3.new(1,1,1); t.Font = Enum.Font.SourceSansBold; t.TextSize = 14
    tileCount = tileCount + 1; makeTileDraggable(t)
    
    local function openEdit() 
        _G.CurrentTile = t; Pages.Cmd.Visible = false; Pages.Set.Visible = false; Pages.Edit.Visible = true
        opIn.Text = tostring(1-t.BackgroundTransparency)
    end
    
    t.MouseButton2Click:Connect(openEdit)
    local holding = false
    t.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then holding = true; task.delay(0.6, function() if holding then openEdit() end end) end end)
    t.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch then holding = false end end)
    t.MouseButton1Click:Connect(function() if not Pages.Edit.Visible then cb() end end)
end

-- Commands (Only Non-Perk Tools)
addCmd("TP to Player", function() loadstring(game:HttpGet("https://pastebin.com/raw/AbDM2er1"))() end)
addCmd("Fling Player", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))() end)
addCmd("Inf Yield", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
addCmd("MM2 Troll", function() loadstring(game:HttpGet('https://raw.githubusercontent.com/Vertex-Hub/Vertex/main/Main.lua'))() end)
addCmd("Eagle Eye", function() _G.esp = not _G.esp; for _,p in pairs(Players:GetPlayers()) do if p.Character then if _G.esp then local h = Instance.new("Highlight", p.Character); h.FillColor = Color3.new(1,0,0) elseif p.Character:FindFirstChild("Highlight") then p.Character.Highlight:Destroy() end end end end)
addCmd("Night Vision", function() Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.Brightness = 2; Lighting.FogEnd = 100000 end)
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

local SetBackBtn = Instance.new("TextButton", Pages.Set); SetBackBtn.Size = UDim2.new(1, -10, 0, 40); SetBackBtn.Text = "BACK TO COMMANDS"; SetBackBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215); SetBackBtn.TextColor3 = Color3.new(1,1,1); SetBackBtn.Font = Enum.Font.SourceSansBold
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
