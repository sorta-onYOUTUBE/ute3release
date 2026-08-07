-- [[ 9K9W TROLL EM 1.2 - GHOST PREDATOR FINAL EDITION (FIXED HOLD) ]]
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "9K9W_GhostPredator"
ScreenGui.ResetOnSpawn = false

-- [[ GLOBAL STATE ]]
local _G = { 
    r = 25, g = 25, b = 25, flySpeed = 50,
    flying = false, infJump = false, noclip = false, predator = false,
    minimized = false, target = "", CurrentTile = nil, grid = 64
}

-- [[ 1. THE CONTEXT MENU ]]
local ContextMenu = Instance.new("Frame", ScreenGui)
ContextMenu.Size = UDim2.new(0, 150, 0, 180); ContextMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ContextMenu.Visible = false; ContextMenu.ZIndex = 1500 
Instance.new("UIStroke", ContextMenu).Color = Color3.fromRGB(0, 255, 150)
Instance.new("UIListLayout", ContextMenu)

local function createSizeBtn(txt, sizeDir)
    local b = Instance.new("TextButton", ContextMenu)
    b.Size = UDim2.new(1, 0, 0, 45); b.Text = txt; b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.SourceSansBold; b.TextSize = 16; b.BorderSizePixel = 0; b.ZIndex = 1501
    b.MouseButton1Click:Connect(function()
        if _G.CurrentTile then _G.CurrentTile.Size = sizeDir; ContextMenu.Visible = false end
    end)
end

createSizeBtn("SMALL", UDim2.new(0, 60, 0, 60))
createSizeBtn("MEDIUM", UDim2.new(0, 120, 0, 120))
createSizeBtn("WIDE", UDim2.new(0, 248, 0, 120))
createSizeBtn("LARGE", UDim2.new(0, 248, 0, 248))

local UIScale = Instance.new("UIScale", ScreenGui)

-- [[ 2. DRAG & GRID SNAP ]]
local function makeTileDraggable(tile)
    local dragging, dragStart, startPos
    tile.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not ContextMenu.Visible then
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
            dragging = false 
            local snapX = math.round(tile.Position.X.Offset / _G.grid) * _G.grid
            local snapY = math.round(tile.Position.Y.Offset / _G.grid) * _G.grid
            tile.Position = UDim2.new(0, snapX, 0, snapY)
        end
    end)
end

-- [[ 3. MAIN UI STRUCTURE ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 600, 0, 480); Main.Position = UDim2.new(0.5, -300, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(_G.r, _G.g, _G.b); Main.BorderSizePixel = 0; Main.Visible = false

local TopBar = Instance.new("Frame", Main); TopBar.Size = UDim2.new(1, 0, 0, 35); TopBar.BackgroundTransparency = 1
local CloseBtn = Instance.new("TextButton", TopBar); CloseBtn.Size = UDim2.new(0, 35, 0, 35); CloseBtn.Position = UDim2.new(1, -35, 0, 0); CloseBtn.Text = "X"; CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); CloseBtn.TextColor3 = Color3.new(1,1,1)
local MinBtn = Instance.new("TextButton", TopBar); MinBtn.Size = UDim2.new(0, 35, 0, 35); MinBtn.Position = UDim2.new(1, -70, 0, 0); MinBtn.Text = "-"; MinBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 0); MinBtn.TextColor3 = Color3.new(1,1,1)

local Content = Instance.new("Frame", Main); Content.Size = UDim2.new(1, 0, 1, -35); Content.Position = UDim2.new(0, 0, 0, 35); Content.BackgroundTransparency = 1
local Pages = { Cmd = Instance.new("ScrollingFrame", Content), Set = Instance.new("ScrollingFrame", Content) }

for n, p in pairs(Pages) do 
    p.Size = UDim2.new(1, -20, 1, -20); p.Position = UDim2.new(0, 10, 0, 10); p.BackgroundTransparency = 1; p.CanvasSize = UDim2.new(0,0,5,0); p.Visible = (n == "Cmd") 
end

local BackBtn = Instance.new("TextButton", Main); BackBtn.Size = UDim2.new(0, 120, 0, 40); BackBtn.Position = UDim2.new(0, 10, 1, -50); BackBtn.Text = "MAIN MENU"; BackBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215); BackBtn.TextColor3 = Color3.new(1,1,1); BackBtn.Font = Enum.Font.SourceSansBold; BackBtn.Visible = false; BackBtn.ZIndex = 10
BackBtn.MouseButton1Click:Connect(function() Pages.Cmd.Visible = true; Pages.Set.Visible = false; BackBtn.Visible = false end)

-- [[ 4. COMMAND ENGINE ]]
local tileCount = 0
local function addCmd(n, cb)
    local clrs = {Color3.fromRGB(0,120,215), Color3.fromRGB(16,124,16), Color3.fromRGB(202,80,16), Color3.fromRGB(150,0,200), Color3.fromRGB(0,150,150)}
    local t = Instance.new("TextButton", Pages.Cmd)
    t.Size = UDim2.new(0, 120, 0, 120)
    t.Position = UDim2.new(0, (tileCount % 4) * 128, 0, math.floor(tileCount / 4) * 128)
    t.Text = n:upper(); t.BackgroundColor3 = clrs[math.random(1,#clrs)]
    t.BorderSizePixel = 0; t.TextColor3 = Color3.new(1,1,1); t.Font = Enum.Font.SourceSansBold; t.TextSize = 12
    tileCount = tileCount + 1
    makeTileDraggable(t)

    -- PC Right Click
    t.MouseButton2Click:Connect(function() 
        _G.CurrentTile = t
        ContextMenu.Position = UDim2.new(0, UIS:GetMouseLocation().X, 0, UIS:GetMouseLocation().Y - 35)
        ContextMenu.Visible = true 
    end)

    -- Mobile/Touch Hold Logic
    local holding = false
    t.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            holding = true
            local startPos = input.Position
            task.delay(0.6, function()
                if holding and (input.Position - startPos).Magnitude < 10 then
                    _G.CurrentTile = t
                    ContextMenu.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y)
                    ContextMenu.Visible = true
                end
            end)
        end
    end)
    t.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then holding = false end
    end)

    t.MouseButton1Click:Connect(function() if not ContextMenu.Visible then cb() end end)
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
addCmd("Settings", function() Pages.Cmd.Visible = false; Pages.Set.Visible = true; BackBtn.Visible = true end)
addCmd("Rejoin", function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end)

-- [[ 5. SETTINGS PAGE ]]
local SLayout = Instance.new("UIListLayout", Pages.Set); SLayout.Padding = UDim.new(0, 10)
local function addSet(txt, val, cb)
    local l = Instance.new("TextLabel", Pages.Set); l.Size = UDim2.new(1,0,0,20); l.Text = txt; l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1; l.TextXAlignment = "Left"
    local b = Instance.new("TextBox", Pages.Set); b.Size = UDim2.new(1,-10,0,30); b.BackgroundColor3 = Color3.fromRGB(40,40,40); b.TextColor3 = Color3.new(1,1,1); b.Text = tostring(_G[val])
    b.FocusLost:Connect(function() _G[val] = tonumber(b.Text) or b.Text; if cb then cb() end end)
end
local function updateBG() Main.BackgroundColor3 = Color3.fromRGB(_G.r, _G.g, _G.b) end
addSet("RGB Red", "r", updateBG); addSet("RGB Green", "g", updateBG); addSet("RGB Blue", "b", updateBG)
addSet("Predator Target", "target", nil)

-- [[ 6. DEVICE PICKER & MAIN DRAG ]]
local Popup = Instance.new("Frame", ScreenGui); Popup.Size = UDim2.new(0, 320, 0, 260); Popup.Position = UDim2.new(0.5, -160, 0.5, -130); Popup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UIStroke", Popup).Color = Color3.fromRGB(0, 255, 150); Instance.new("UICorner", Popup)
local function launch(sc) UIScale.Scale = sc; Popup:Destroy(); Main.Visible = true end
local function makePopBtn(txt, y, clr, sc)
    local b = Instance.new("TextButton", Popup); b.Size = UDim2.new(0, 260, 0, 45); b.Position = UDim2.new(0.5, -130, 0, y); b.Text = txt; b.BackgroundColor3 = clr; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.SourceSansBold
    b.MouseButton1Click:Connect(function() launch(sc) end)
end
makePopBtn("MOBILE", 70, Color3.fromRGB(200, 50, 50), 0.6); makePopBtn("TABLET", 125, Color3.fromRGB(200, 150, 0), 0.8); makePopBtn("PC", 180, Color3.fromRGB(0, 120, 215), 1.0)

local dStart, sPos, drg; TopBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drg = true; dStart = i.Position; sPos = Main.Position end end)
UIS.InputChanged:Connect(function(i) if drg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - dStart; Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function() drg = false end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
MinBtn.MouseButton1Click:Connect(function() _G.minimized = not _G.minimized; Main:TweenSize(_G.minimized and UDim2.new(0, 600, 0, 35) or UDim2.new(0, 600, 0, 480), "Out", "Quad", 0.3, true) end)

-- Runtime
RunService.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        if _G.noclip then for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
        if _G.flying then LP.Character.HumanoidRootPart.Velocity = Camera.CFrame.LookVector * _G.flySpeed end
        if _G.predator and _G.target ~= "" then
            local t = Players:FindFirstChild(_G.target)
            if t and t.Character then LP.Character.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3) end
        end
    end
end)
UIS.JumpRequest:Connect(function() if _G.infJump then LP.Character.Humanoid:ChangeState("Jumping") end end)
UIS.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then ContextMenu.Visible = false end end)
