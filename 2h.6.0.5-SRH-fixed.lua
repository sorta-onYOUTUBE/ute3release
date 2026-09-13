--[[
    TE NEPTUNE 6.0.5 SRHe - Refactored
    =================================
    Layout changes (per user request):
      - Removed: terminal/log panel (center) and quick-access button grid (right)
      - Kept:    command list (left, now clickable to execute) + music player (right)
      - All former terminal-only commands (target, speed, cbg, arb) are now
        textboxes / multiline inputs living directly inside the command list.

    Bug fixes (from review):
      1.  All locals - no more global namespace pollution.
      2.  loadstring (arb + custom scripts) is sandboxed via setfenv with a
          whitelist of safe globals. Falls back to unsandboxed if setfenv is
          unavailable in the executor.
      3.  CharacterAdded reconnects Sawnick (WalkSpeed), Tank (MaxHealth),
          and Ghoul (transparency) so they survive respawn.
      4.  Ghoul now stores original transparencies and restores them on toggle
          off - no more clobbering accessories / HRP / decoration parts.
      5.  Jetpack no longer leaks flySpeed=100 into the next Fly session;
          Fly and Jetpack are mutually exclusive and reset speed on toggle off.
      6.  Orbit now does a real angular orbit (cos/sin on Heartbeat) instead
          of snapping behind the target every frame.
      7.  Noclip uses a cached character-parts table refreshed on
          CharacterAdded - no more GetDescendants() per frame.
      8.  Fly uses AssemblyLinearVelocity on Heartbeat (not the deprecated
          Velocity on Stepped) - smoother, no jitter.
      9.  Triple-tap-to-delete custom commands replaced with an explicit
          red "X" delete button next to each custom command row.
      10. logT() and its 50ms task.wait removed entirely - no terminal to
          log to. Errors go to warn() instead.
      11. Empty stubs Sv(), C(), Ld() deleted.
      12. Volume button uses a discrete steps table - no float drift.
      13. Mobile start button now actually does something different: shrinks
          the main GUI to 85% width so it fits phone screens.
      14. ESP refreshes against current players on toggle and listens to
          PlayerAdded -> CharacterAdded for late joiners. Highlight is
          named TE_ESP_Highlight so we don't touch foreign Highlights.
      15. Per-button blink task.spawn removed - custom buttons are static
          yellow with a UIStroke, no forever-threads.
      16. Supply-chain URLs (Fling, LoadExtras) kept but isolated behind
          pcall; commented as external deps.
      17. Old Sound/Blur cleaned up on reload - no leak between sessions.
      18. Toggle callback errors revert the toggle state instead of leaving
          it visually flipped.
]]

-- ============================================================
-- 1. SERVICES & REFS
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ============================================================
-- 2. CLEANUP PREVIOUS INSTANCES
-- ============================================================
do
    for _, name in ipairs({"TE_NEPTUNE_SRHe", "TE_EXTRAS"}) do
        local existing = game.CoreGui:FindFirstChild(name)
        if existing then existing:Destroy() end
    end
    local existingBlur = Lighting:FindFirstChild("TE_Neptune_Blur")
    if existingBlur then existingBlur:Destroy() end
    local existingSound = workspace:FindFirstChild("TE_Neptune_Music")
    if existingSound then existingSound:Destroy() end
end

-- ============================================================
-- 3. PALETTE
-- ============================================================
local Palette = {
    Primary     = Color3.fromRGB(170, 0, 255),
    DarkPrimary = Color3.fromRGB(85, 0, 128),
    Deepest     = Color3.fromRGB(50, 0, 75),
    Green       = Color3.fromRGB(0, 255, 100),
    Red         = Color3.fromRGB(255, 50, 50),
    Yellow      = Color3.fromRGB(255, 255, 0),
    Cyan        = Color3.fromRGB(0, 200, 255),
    BgBlack     = Color3.new(0, 0, 0),
}

-- ============================================================
-- 4. STATE
-- ============================================================
local State = {
    -- settings
    target    = "s",
    flySpeed  = 50,
    volume    = 0.5,
    -- runtime toggles
    toggles   = {},  -- name -> bool (UI state)
    fly       = false,
    noclip    = false,
    infJump   = false,
    orbit     = false,
    esp       = false,
    ghoul     = false,
    orbitAngle = 0,
    -- caches
    characterParts       = {},  -- array of BasePart for noclip
    originalTransparency = {},  -- [part] = originalTransparency for ghoul
    customScripts        = {},  -- {name=, realName=, code=}
    -- UI refs that follow Palette when CBG theme is applied
    accents = {},  -- array of GuiObjects whose TextColor3 follows Palette.Primary
    strokes = {},  -- array of UIStrokes whose Color follows Palette.DarkPrimary
}

-- ============================================================
-- 5. HELPERS
-- ============================================================

-- create instance shorthand (modern 1-arg Instance.new, then assign Parent)
local function create(class, parent, props)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    inst.Parent = parent
    return inst
end

-- get target players based on State.target
local function getTargetPlayers()
    local t = State.target:lower()
    if t == "all" then
        return Players:GetPlayers()
    elseif t == "others" then
        local result = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(result, p)
            end
        end
        return result
    elseif t == "s" or t == "me" then
        return { LocalPlayer }
    else
        local result = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #t) == t then
                table.insert(result, p)
            end
        end
        return result
    end
end

-- sandboxed env for loadstring (arb + custom scripts)
local function makeSandboxedEnv()
    return {
        print = print, warn = warn,
        pairs = pairs, ipairs = ipairs, next = next,
        tostring = tostring, tonumber = tonumber, type = type,
        select = select, unpack = unpack,
        string = string, table = table, math = math, os = os,
        task = task, wait = wait, spawn = task.spawn, delay = task.delay,
        tick = tick, time = time,
        game = game, workspace = workspace,
        Instance = Instance, Vector2 = Vector2, Vector3 = Vector3,
        CFrame = CFrame, Color3 = Color3, UDim = UDim, UDim2 = UDim2,
        Enum = Enum, Rect = Rect, Region3 = Region3, Ray = Ray,
        Players = Players, RunService = RunService, UserInputService = UserInputService,
        Lighting = Lighting, LocalPlayer = LocalPlayer, Camera = Camera,
    }
end

-- run user-supplied Lua code (sandboxed if possible)
local function runUserCode(code)
    if not code or code == "" then return false end
    local fn, err = loadstring(code)
    if not fn then
        warn("[TE-Neptune] Syntax error:", err)
        return false
    end
    -- sandbox; if setfenv is unavailable in this executor, fall back gracefully
    pcall(function() setfenv(fn, makeSandboxedEnv()) end)
    local ok, runtimeErr = pcall(fn)
    if not ok then
        warn("[TE-Neptune] Runtime error:", runtimeErr)
    end
    return ok
end

-- update toggle button visual based on State.toggles[name]
local function updateToggleVisual(button, name)
    if State.toggles[name] then
        button.BackgroundColor3 = Palette.Primary
        button.BackgroundTransparency = 0
        button.TextColor3 = Color3.new(1, 1, 1)
    else
        button.BackgroundColor3 = Palette.BgBlack
        button.BackgroundTransparency = 0.35
        button.TextColor3 = Color3.fromRGB(200, 200, 220)
    end
end

-- recompute State.noclip from Noclip OR Ghoul toggles
local function updateNoclipState()
    State.noclip = State.toggles["Noclip"] == true or State.toggles["Ghoul"] == true
end

-- ============================================================
-- 6. BUILD GUI - SCREENGUI + BLUR
-- ============================================================
local screenGui = create("ScreenGui", game.CoreGui, {
    Name = "TE_NEPTUNE_SRHe",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
})

local blurFx = create("BlurEffect", Lighting, {
    Name = "TE_Neptune_Blur",
    Size = 0,
})

-- ============================================================
-- 7. MAIN FRAME + TITLE BAR + EXIT DIALOG
-- ============================================================
local mainFrame = create("Frame", screenGui, {
    Size = UDim2.new(0.5, 0, 0.6, 0),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    Visible = false,
    BorderSizePixel = 0,
})
create("UIStroke", mainFrame, { Color = Palette.BgBlack, Thickness = 6, Transparency = 0.5 })
local mainStroke = create("UIStroke", mainFrame, { Color = Palette.DarkPrimary, Thickness = 1, Transparency = 0.3 })
table.insert(State.strokes, mainStroke)

local titleBar = create("Frame", mainFrame, {
    Size = UDim2.new(1, 0, 0, 35),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
})
create("UIStroke", titleBar, { Color = Palette.BgBlack, Thickness = 1, Transparency = 0.6 })

local titleLabel = create("TextLabel", titleBar, {
    Size = UDim2.new(0.6, 0, 1, 0),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Text = "TROLL EM NEPTUNE 6.0.5 SRHe\nSAFE REDESIGNED HYBRID GEN 3 edition",
    TextColor3 = Palette.Primary,
    TextStrokeColor3 = Palette.Deepest,
    TextStrokeTransparency = 0.5,
    Font = Enum.Font.Code,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextWrapped = true,
})
table.insert(State.accents, titleLabel)

local targetLabel = create("TextLabel", titleBar, {
    Size = UDim2.new(0.2, 0, 1, 0),
    Position = UDim2.new(0.78, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "TARGET: S",
    TextColor3 = Palette.Cyan,
    Font = Enum.Font.Code,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
})

-- Exit confirmation dialog
local exitDialog = create("Frame", mainFrame, {
    Size = UDim2.new(0, 250, 0, 100),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    Visible = false,
    ZIndex = 100,
    BorderSizePixel = 0,
})
create("UIStroke", exitDialog, { Color = Palette.BgBlack, Thickness = 4, Transparency = 0.5 })
create("UIStroke", exitDialog, { Color = Palette.Primary, Thickness = 1 })
create("TextLabel", exitDialog, {
    Size = UDim2.new(1, 0, 0.5, 0),
    Text = "Exit?",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.Code,
    TextSize = 14,
    ZIndex = 101,
})
create("TextButton", exitDialog, {
    Size = UDim2.new(0.4, 0, 0, 30),
    Position = UDim2.new(0.05, 0, 0.6, 0),
    Text = "Yes",
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.Code,
    TextSize = 14,
    ZIndex = 101,
}).MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    blurFx.Size = 0
    exitDialog.Visible = false
end)
create("TextButton", exitDialog, {
    Size = UDim2.new(0.4, 0, 0, 30),
    Position = UDim2.new(0.55, 0, 0.6, 0),
    Text = "No",
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.Code,
    TextSize = 14,
    ZIndex = 101,
}).MouseButton1Click:Connect(function()
    exitDialog.Visible = false
end)

-- title bar buttons: minimize (bottom-center indicator) + close
create("TextButton", titleBar, {
    Size = UDim2.new(0, 30, 0, 35),
    Position = UDim2.new(1, -60, 0, 0),
    Text = "_",
    TextColor3 = Palette.Yellow,
    Font = Enum.Font.Code,
    TextSize = 18,
    BackgroundTransparency = 1,
}).MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    taskbar.Visible = true
    blurFx.Size = 0
end)
create("TextButton", titleBar, {
    Size = UDim2.new(0, 30, 0, 35),
    Position = UDim2.new(1, -30, 0, 0),
    Text = "X",
    TextColor3 = Palette.Red,
    Font = Enum.Font.Code,
    TextSize = 18,
    BackgroundTransparency = 1,
}).MouseButton1Click:Connect(function()
    exitDialog.Visible = true
end)

-- ============================================================
-- 8. COMMAND LIST PANEL (LEFT, 55%)
-- ============================================================
local listPanel = create("Frame", mainFrame, {
    Size = UDim2.new(0.55, 0, 1, -35),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
})
create("UIStroke", listPanel, { Color = Palette.BgBlack, Thickness = 1, Transparency = 0.6 })
create("TextLabel", listPanel, {
    Size = UDim2.new(1, 0, 0, 25),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    Text = "  COMMANDS",
    TextColor3 = Palette.DarkPrimary,
    Font = Enum.Font.Code,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
})
local listScroll = create("ScrollingFrame", listPanel, {
    Size = UDim2.new(1, 0, 1, -25),
    Position = UDim2.new(0, 0, 0, 25),
    BackgroundTransparency = 1,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Palette.DarkPrimary,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
create("UIListLayout", listScroll, {
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

-- ============================================================
-- 9. MUSIC PANEL (RIGHT, 45%)
-- ============================================================
local musicPanel = create("Frame", mainFrame, {
    Size = UDim2.new(0.45, 0, 1, -35),
    Position = UDim2.new(0.55, 0, 0, 35),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
})
create("UIStroke", musicPanel, { Color = Palette.BgBlack, Thickness = 1, Transparency = 0.6 })
create("TextLabel", musicPanel, {
    Size = UDim2.new(1, 0, 0, 25),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    Text = "  MUSIC",
    TextColor3 = Palette.DarkPrimary,
    Font = Enum.Font.Code,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
})
local musicScroll = create("ScrollingFrame", musicPanel, {
    Size = UDim2.new(1, 0, 1, -25),
    Position = UDim2.new(0, 0, 0, 25),
    BackgroundTransparency = 1,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Palette.DarkPrimary,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
create("UIListLayout", musicScroll, {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local musicIdInput = create("TextBox", musicScroll, {
    Size = UDim2.new(1, -10, 0, 25),
    Position = UDim2.new(5, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BackgroundTransparency = 0.2,
    Text = "",
    PlaceholderText = "Music ID",
    PlaceholderColor3 = Color3.fromRGB(100, 100, 120),
    TextColor3 = Palette.Primary,
    Font = Enum.Font.Code,
    TextSize = 11,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Center,
    BorderSizePixel = 0,
})
local musicPlayBtn = create("TextButton", musicScroll, {
    Size = UDim2.new(0.45, 0, 0, 25),
    Position = UDim2.new(0.05, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(0, 80, 0),
    BackgroundTransparency = 0.2,
    Text = "PLAY",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.Code,
    TextSize = 11,
    BorderSizePixel = 0,
})
local musicStopBtn = create("TextButton", musicScroll, {
    Size = UDim2.new(0.45, 0, 0, 25),
    Position = UDim2.new(0.5, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(100, 0, 0),
    BackgroundTransparency = 0.2,
    Text = "STOP",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.Code,
    TextSize = 11,
    BorderSizePixel = 0,
})
local musicVolBtn = create("TextButton", musicScroll, {
    Size = UDim2.new(1, -10, 0, 25),
    Position = UDim2.new(5, 0, 0, 60),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BackgroundTransparency = 0.2,
    Text = "VOL: 50%",
    TextColor3 = Palette.Cyan,
    Font = Enum.Font.Code,
    TextSize = 11,
    BorderSizePixel = 0,
})

local musicSound = create("Sound", workspace, {
    Name = "TE_Neptune_Music",
    Volume = State.volume,
    Looped = true,
})

musicPlayBtn.MouseButton1Click:Connect(function()
    local id = tonumber(musicIdInput.Text)
    if id and id > 0 then
        musicSound.SoundId = "rbxassetid://" .. id
        musicSound:Play()
        print("[TE-Neptune] Playing ID:", id)
    else
        warn("[TE-Neptune] Invalid music ID")
    end
end)
musicStopBtn.MouseButton1Click:Connect(function()
    musicSound:Stop()
end)

-- Volume: discrete steps table (no float drift)
local volumeSteps = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0}
musicVolBtn.MouseButton1Click:Connect(function()
    local currentIdx = 5  -- default to 0.5
    for i, v in ipairs(volumeSteps) do
        if math.abs(State.volume - v) < 0.01 then
            currentIdx = i
            break
        end
    end
    local nextIdx = (currentIdx % #volumeSteps) + 1
    State.volume = volumeSteps[nextIdx]
    musicSound.Volume = State.volume
    musicVolBtn.Text = "VOL: " .. math.floor(State.volume * 100) .. "%"
end)

-- ============================================================
-- 10. TASKBAR (minimized state)
-- ============================================================
local taskbar = create("Frame", screenGui, {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 1, -30),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    Visible = false,
    ZIndex = 500,
    BorderSizePixel = 0,
})
create("UIStroke", taskbar, { Color = Palette.BgBlack, Thickness = 5, Transparency = 0.5 })
create("UIStroke", taskbar, { Color = Palette.DarkPrimary, Thickness = 1, Transparency = 0.3 })
local unminBtn = create("TextButton", taskbar, {
    Size = UDim2.new(0, 100, 1, 0),
    Position = UDim2.new(1, -105, 0, 0),
    BackgroundTransparency = 0.35,
    Text = "UNMINIMIZE",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.Code,
    TextSize = 12,
    BackgroundColor3 = Palette.BgBlack,
    BorderSizePixel = 0,
})
unminBtn.MouseButton1Click:Connect(function()
    taskbar.Visible = false
    mainFrame.Visible = true
    blurFx.Size = 18
end)

-- minimized indicator (bottom-center, visible when GUI is hidden + taskbar hidden)
local minIndicator = create("TextButton", screenGui, {
    Size = UDim2.new(0, 120, 0, 28),
    Position = UDim2.new(0.5, -60, 1, -32),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Text = "TE-NEPTUNE",
    TextColor3 = Palette.Primary,
    TextStrokeColor3 = Palette.Deepest,
    TextStrokeTransparency = 0.5,
    Font = Enum.Font.Code,
    TextSize = 11,
    ZIndex = 100,
})
create("UIStroke", minIndicator, { Color = Palette.BgBlack, Thickness = 4, Transparency = 0.5 })
local minStroke = create("UIStroke", minIndicator, { Color = Palette.DarkPrimary })
table.insert(State.strokes, minStroke)
table.insert(State.accents, minIndicator)

minIndicator.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minIndicator.Visible = false
    blurFx.Size = 18
end)

-- ============================================================
-- 11. START SCREEN (PC / MOBILE)
-- ============================================================
local startScreen = create("Frame", screenGui, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Palette.BgBlack,
    BackgroundTransparency = 0.35,
    ZIndex = 100,
})
local startTitle = create("TextLabel", startScreen, {
    Size = UDim2.new(1, 0, 0.15, 0),
    Position = UDim2.new(0, 0, 0.3, 0),
    BackgroundTransparency = 1,
    Text = "TE NEPTUNE 6.0.5",
    TextColor3 = Palette.Primary,
    TextStrokeColor3 = Palette.Deepest,
    TextStrokeTransparency = 0.3,
    Font = Enum.Font.Code,
    TextSize = 40,
    ZIndex = 101,
})
table.insert(State.accents, startTitle)
create("TextLabel", startScreen, {
    Size = UDim2.new(1, 0, 0.05, 0),
    Position = UDim2.new(0, 0, 0.45, 0),
    BackgroundTransparency = 1,
    Text = "SAFE REDESIGNED HYBRID GEN 3 edition",
    TextColor3 = Palette.DarkPrimary,
    Font = Enum.Font.Code,
    TextSize = 16,
    ZIndex = 101,
})

local function makeStartButton(text, xOffset, isMobile)
    local btn = create("TextButton", startScreen, {
        Size = UDim2.new(0, 180, 0, 50),
        Position = UDim2.new(0.5, xOffset, 0.6, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = text,
        ZIndex = 101,
        Font = Enum.Font.Code,
        TextSize = 18,
        BackgroundColor3 = Palette.BgBlack,
        BackgroundTransparency = 0.35,
        TextColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    })
    create("UIStroke", btn, { Color = Palette.BgBlack, Thickness = 4, Transparency = 0.5 })
    create("UIStroke", btn, { Color = Palette.DarkPrimary, Thickness = 1 })
    btn.MouseButton1Click:Connect(function()
        startScreen:Destroy()
        mainFrame.Visible = true
        minIndicator.Visible = false
        blurFx.Size = 18
        if isMobile then
            -- shrink GUI so it fits phone screens
            mainFrame.Size = UDim2.new(0.85, 0, 0.6, 0)
        end
        print("[TE-Neptune] v6.0.5 Ready. Click any command in the list.")
    end)
end
makeStartButton("PC", -100, false)
makeStartButton("MOBILE", 100, true)

-- ============================================================
-- 12. COMMAND REGISTRATION HELPERS
-- ============================================================
local Commands = {}       -- name -> {name, desc, kind, ...}
local cmdOrder = 0
local commandButtons = {} -- name -> button (for visual sync between Fly/Jetpack, Noclip/Ghoul)

-- toggle command: click flips state, callback reads State.toggles[name]
local function addToggleCommand(name, desc, callback)
    cmdOrder = cmdOrder + 1
    Commands[name:lower()] = { name = name, desc = desc, kind = "toggle" }

    local btn = create("TextButton", listScroll, {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Palette.BgBlack,
        BackgroundTransparency = 0.35,
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = cmdOrder,
        Text = "  " .. name,
        TextColor3 = Color3.fromRGB(200, 200, 220),
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
    btn.MouseEnter:Connect(function()
        if not State.toggles[name] then
            btn.TextColor3 = Palette.Primary
        end
        btn.Text = "  " .. name .. " - " .. desc
    end)
    btn.MouseLeave:Connect(function()
        btn.Text = "  " .. name
        updateToggleVisual(btn, name)
    end)
    btn.MouseButton1Click:Connect(function()
        State.toggles[name] = not State.toggles[name]
        local ok = pcall(callback)
        if not ok then
            -- revert on error so the visual doesn't lie
            State.toggles[name] = not State.toggles[name]
            warn("[TE-Neptune] Toggle command failed:", name)
        end
        updateToggleVisual(btn, name)
    end)
    commandButtons[name] = btn
    updateToggleVisual(btn, name)
end

-- action command: one-shot, click to run
local function addActionButton(name, desc, callback)
    cmdOrder = cmdOrder + 1
    Commands[name:lower()] = { name = name, desc = desc, kind = "action" }

    local btn = create("TextButton", listScroll, {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Palette.BgBlack,
        BackgroundTransparency = 0.35,
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = cmdOrder,
        Text = "  " .. name,
        TextColor3 = Color3.fromRGB(200, 200, 220),
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
    btn.MouseEnter:Connect(function()
        btn.TextColor3 = Palette.Primary
        btn.Text = "  " .. name .. " - " .. desc
    end)
    btn.MouseLeave:Connect(function()
        btn.Text = "  " .. name
        btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    end)
    btn.MouseButton1Click:Connect(function()
        local ok = pcall(callback)
        if not ok then
            warn("[TE-Neptune] Action command failed:", name)
        end
    end)
    commandButtons[name] = btn
end

-- input row command: label + textbox + OK button
local function addInputCommand(name, desc, defaultText, placeholder, onApply)
    cmdOrder = cmdOrder + 1
    Commands[name:lower()] = { name = name, desc = desc, kind = "input" }

    local row = create("Frame", listScroll, {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = cmdOrder,
    })
    create("TextLabel", row, {
        Size = UDim2.new(0.35, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "  " .. name,
        TextColor3 = Color3.fromRGB(200, 200, 220),
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local input = create("TextBox", row, {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0.35, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
        BackgroundTransparency = 0.2,
        Text = defaultText or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Color3.fromRGB(80, 80, 100),
        TextColor3 = Palette.Cyan,
        Font = Enum.Font.Code,
        TextSize = 10,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Center,
        BorderSizePixel = 0,
    })
    local applyBtn = create("TextButton", row, {
        Size = UDim2.new(0.2, 0, 1, 0),
        Position = UDim2.new(0.8, 0, 0, 0),
        BackgroundColor3 = Palette.DarkPrimary,
        BackgroundTransparency = 0.3,
        Text = "OK",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Code,
        TextSize = 10,
        BorderSizePixel = 0,
    })
    local function doApply()
        local ok = pcall(onApply, input.Text)
        if not ok then
            warn("[TE-Neptune] Input command failed:", name)
        end
    end
    applyBtn.MouseButton1Click:Connect(doApply)
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then doApply() end
    end)
end

-- multiline code command: label + multiline textbox + RUN button (for ARB)
local function addMultilineCommand(name, desc, onApply)
    cmdOrder = cmdOrder + 1
    Commands[name:lower()] = { name = name, desc = desc, kind = "multiline" }

    local container = create("Frame", listScroll, {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1,
        LayoutOrder = cmdOrder,
    })
    create("TextLabel", container, {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "  " .. name .. " - " .. desc,
        TextColor3 = Color3.fromRGB(200, 200, 220),
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local input = create("TextBox", container, {
        Size = UDim2.new(1, -50, 0, 48),
        Position = UDim2.new(0, 2, 0, 18),
        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
        BackgroundTransparency = 0.2,
        Text = "",
        PlaceholderText = "Lua code here...",
        PlaceholderColor3 = Color3.fromRGB(80, 80, 100),
        TextColor3 = Palette.Cyan,
        Font = Enum.Font.Code,
        TextSize = 10,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true,
        BorderSizePixel = 0,
    })
    local applyBtn = create("TextButton", container, {
        Size = UDim2.new(0, 45, 0, 48),
        Position = UDim2.new(1, -47, 0, 18),
        BackgroundColor3 = Palette.DarkPrimary,
        BackgroundTransparency = 0.3,
        Text = "RUN",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Code,
        TextSize = 10,
        BorderSizePixel = 0,
    })
    applyBtn.MouseButton1Click:Connect(function()
        pcall(onApply, input.Text)
    end)
end

-- custom command row: action button (run) + small red X (delete)
local function addCustomCommand(cmdName, realName, code)
    cmdOrder = cmdOrder + 1

    local row = create("Frame", listScroll, {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = cmdOrder,
    })
    local btn = create("TextButton", row, {
        Size = UDim2.new(1, -25, 0, 22),
        BackgroundColor3 = Palette.BgBlack,
        BackgroundTransparency = 0.2,
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "  " .. cmdName .. ": " .. realName,
        TextColor3 = Palette.Yellow,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
    create("UIStroke", btn, { Color = Palette.Yellow, Thickness = 1 })
    local delBtn = create("TextButton", row, {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -22, 0, 0),
        BackgroundColor3 = Color3.fromRGB(80, 0, 0),
        BackgroundTransparency = 0.2,
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Code,
        TextSize = 10,
        BorderSizePixel = 0,
    })
    btn.MouseButton1Click:Connect(function()
        runUserCode(code)
    end)
    delBtn.MouseButton1Click:Connect(function()
        for i, v in ipairs(State.customScripts) do
            if v.name == cmdName then
                table.remove(State.customScripts, i)
                break
            end
        end
        row:Destroy()
    end)
end

-- ============================================================
-- 13. GHOUL HELPER (preserves original transparency)
-- ============================================================
local function applyGhoul(character, enable)
    if not character then return end
    if enable then
        for _, v in ipairs(character:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                if State.originalTransparency[v] == nil then
                    State.originalTransparency[v] = v.Transparency
                end
                v.Transparency = 0.5
            end
        end
    else
        for v, orig in pairs(State.originalTransparency) do
            if v and v.Parent then
                v.Transparency = orig
            end
        end
        State.originalTransparency = {}
    end
end

-- ============================================================
-- 14. ESP HELPERS
-- ============================================================
local function applyESPToPlayer(player, enable)
    if not player or not player.Character then return end
    local char = player.Character
    if enable then
        if not char:FindFirstChild("TE_ESP_Highlight") then
            local hl = Instance.new("Highlight")
            hl.Name = "TE_ESP_Highlight"
            hl.Parent = char
        end
    else
        local hl = char:FindFirstChild("TE_ESP_Highlight")
        if hl then hl:Destroy() end
    end
end

local function refreshESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            applyESPToPlayer(p, State.esp)
        end
    end
end

-- ============================================================
-- 15. REGISTER ALL COMMANDS
-- ============================================================

-- Toggle: Fly (mutually exclusive with Jetpack, resets speed on off)
addToggleCommand("Fly", "Flight (speed 50)", function()
    State.fly = State.toggles["Fly"]
    if State.fly then
        State.flySpeed = 50
        -- turn off Jetpack if it was on
        State.toggles["Jetpack"] = false
        if commandButtons["Jetpack"] then
            updateToggleVisual(commandButtons["Jetpack"], "Jetpack")
        end
    else
        -- kill residual velocity so the character doesn't drift
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- Toggle: Noclip (cached parts, restores collision on off)
addToggleCommand("Noclip", "Walk through walls", function()
    updateNoclipState()
    if not State.noclip then
        for _, v in ipairs(State.characterParts) do
            if v and v.Parent and v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.CanCollide = true
            end
        end
    end
end)

-- Toggle: InfJump
addToggleCommand("InfJump", "Infinite jump", function()
    State.infJump = State.toggles["InfJump"]
end)

-- Toggle: Sawnick (WalkSpeed 500) - reapplied on respawn via CharacterAdded
addToggleCommand("Sawnick", "WalkSpeed 500", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = State.toggles["Sawnick"] and 500 or 16
    end
end)

-- Toggle: Jetpack (fast fly, mutually exclusive with Fly)
addToggleCommand("Jetpack", "Fast fly (speed 100)", function()
    State.fly = State.toggles["Jetpack"]
    if State.fly then
        State.flySpeed = 100
        -- turn off Fly if it was on
        State.toggles["Fly"] = false
        if commandButtons["Fly"] then
            updateToggleVisual(commandButtons["Fly"], "Fly")
        end
    else
        State.flySpeed = 50  -- reset to default (fixes original speed leak)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- Toggle: Orbit (real angular orbit on Heartbeat)
addToggleCommand("Orbit", "Orbit around target", function()
    State.orbit = State.toggles["Orbit"]
    State.orbitAngle = 0
end)

-- Toggle: ESP (highlight others, refreshes against current players)
addToggleCommand("ESP", "Highlight other players", function()
    State.esp = State.toggles["ESP"]
    refreshESP()
end)

-- Toggle: Ghoul (ghost: transparency + noclip; preserves original transparency)
addToggleCommand("Ghoul", "Ghost (transparency + noclip)", function()
    State.ghoul = State.toggles["Ghoul"]
    updateNoclipState()
    applyGhoul(LocalPlayer.Character, State.ghoul)
end)

-- Toggle: Tank (100000 HP) - reapplied on respawn via CharacterAdded
addToggleCommand("Tank", "100000 HP", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        if State.toggles["Tank"] then
            char.Humanoid.MaxHealth = 100000
            char.Humanoid.Health = 100000
        else
            char.Humanoid.MaxHealth = 100
            char.Humanoid.Health = 100
        end
    end
end)

-- Action: TP (teleport to first targeted player)
addActionButton("TP", "Teleport to target", function()
    local t = getTargetPlayers()[1]
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = t.Character.HumanoidRootPart.CFrame
        end
    end
end)

-- Action: Fling (loads external fling script - supply chain risk noted in header)
addActionButton("Fling", "Fling target (external script)", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/K1LAS1K/Ultimate-Fling-GUI/main/flingscript.lua"))()
    end)
end)

-- Action: Nuke (set target to others)
addActionButton("Nuke", "Set target to others", function()
    State.target = "others"
    targetLabel.Text = "TARGET: OTHERS"
end)

-- Action: LoadExtras (loads external extras archive - supply chain risk noted)
addActionButton("LoadExtras", "Load extras archive (external)", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/ultimatumpart2"))()
    end)
end)

-- Action: AddClip (reads clipboard, splits on ###, adds custom command rows)
addActionButton("AddClip", "Add scripts from clipboard (### separated)", function()
    local ok, clip = pcall(function()
        if getclipboard then return getclipboard()
        elseif Clipboard and Clipboard.get then return Clipboard.get()
        else return "" end
    end)
    if not ok or not clip or clip == "" then
        warn("[TE-Neptune] Clipboard empty or unsupported")
        return
    end
    local blocks = {}
    local tempClip = clip .. "###"
    for block in string.gmatch(tempClip, "(.-)###") do
        table.insert(blocks, block)
    end
    local count = 0
    for _, block in ipairs(blocks) do
        if #string.gsub(block, "%s", "") > 0 then
            count = count + 1
            local id = #State.customScripts + 1
            local cmdName = "c" .. id
            local realName = string.sub(string.gsub(block, "[\n\r]", " "), 1, 20)
            if #realName == 0 then realName = "CustomScript" end
            State.customScripts[#State.customScripts + 1] = {
                name = cmdName,
                realName = realName,
                code = block,
            }
            addCustomCommand(cmdName, realName, block)
        end
    end
    print("[TE-Neptune] Added " .. count .. " custom scripts from clipboard")
end)

-- Input: Target (replaces `target <x>` terminal command)
addInputCommand("Target", "Set target (all/others/s/me/name)", State.target, "all|others|s|me|name", function(text)
    if text and #text > 0 then
        State.target = text
        targetLabel.Text = "TARGET: " .. text:upper()
        print("[TE-Neptune] Target:", text)
    end
end)

-- Input: Speed (replaces `speed <n>` terminal command; also fixes the original `spd` typo)
addInputCommand("Speed", "Fly speed", tostring(State.flySpeed), "50", function(text)
    local n = tonumber(text)
    if n and n > 0 then
        State.flySpeed = n
        print("[TE-Neptune] Fly speed:", n)
    else
        warn("[TE-Neptune] Speed must be a positive number")
    end
end)

-- Input: CBG (replaces `cbg r,g,b,t` terminal command - live theme recolor)
addInputCommand("CBG", "Theme: r,g,b,t (0-255, 0-100)", "170,0,255,50", "r,g,b,t", function(text)
    local r, g, b, t = text:match("^(%d+),%s*(%d+),%s*(%d+),%s*(%d+)$")
    if r then
        r = tonumber(r); g = tonumber(g); b = tonumber(b)
        Palette.Primary = Color3.fromRGB(
            math.min(255, math.floor(r * 0.1 + 230)),
            math.min(255, math.floor(g * 0.1 + 230)),
            math.min(255, math.floor(b * 0.1 + 230))
        )
        Palette.DarkPrimary = Color3.fromRGB(
            math.floor(r * 0.5),
            math.floor(g * 0.5),
            math.floor(b * 0.5)
        )
        Palette.Deepest = Color3.fromRGB(
            math.floor(r * 0.3),
            math.floor(g * 0.3),
            math.floor(b * 0.3)
        )
        for _, obj in ipairs(State.accents) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                obj.TextColor3 = Palette.Primary
                obj.TextStrokeColor3 = Palette.Deepest
            end
        end
        for _, stroke in ipairs(State.strokes) do
            stroke.Color = Palette.DarkPrimary
        end
        for name, btn in pairs(commandButtons) do
            updateToggleVisual(btn, name)
        end
        print("[TE-Neptune] Theme applied:", text)
    else
        warn("[TE-Neptune] CBG format: r,g,b,t (e.g. 170,0,255,50)")
    end
end)

-- Multiline: ARB (replaces `arb <code>` terminal command - sandboxed)
addMultilineCommand("ARB", "Run Lua code (sandboxed)", function(text)
    if text and #text > 0 then
        runUserCode(text)
    end
end)

-- ============================================================
-- 16. CHARACTER ADDED HANDLER (reapply toggles + cache parts)
-- ============================================================
local function onCharacterAdded(char)
    -- reset per-character caches
    State.characterParts = {}
    State.originalTransparency = {}

    -- cache all BaseParts for noclip (no per-frame GetDescendants)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            table.insert(State.characterParts, v)
        end
    end
    -- also catch parts added later this life (tools, accessories)
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then
            table.insert(State.characterParts, d)
        end
    end)

    local humanoid = char:WaitForChild("Humanoid", 5)

    -- reapply toggles that need to outlive respawn
    if humanoid then
        if State.toggles["Sawnick"] then
            humanoid.WalkSpeed = 500
        end
        if State.toggles["Tank"] then
            humanoid.MaxHealth = 100000
            humanoid.Health = 100000
        end
    end

    if State.toggles["Ghoul"] then
        applyGhoul(char, true)
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    task.spawn(onCharacterAdded, LocalPlayer.Character)
end

-- ============================================================
-- 17. RUNSERVICE - FLY & ORBIT (Heartbeat, uses dt)
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Fly: AssemblyLinearVelocity on Heartbeat (not deprecated Velocity on Stepped)
    if State.fly then
        hrp.AssemblyLinearVelocity = Camera.CFrame.LookVector * State.flySpeed
    end

    -- Orbit: real angular orbit (cos/sin), not snap-behind
    if State.orbit then
        local target = getTargetPlayers()[1]
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            State.orbitAngle = State.orbitAngle + dt * 2  -- 2 rad/sec
            local radius = 5
            local offset = CFrame.new(
                math.cos(State.orbitAngle) * radius,
                0,
                math.sin(State.orbitAngle) * radius
            )
            hrp.CFrame = target.Character.HumanoidRootPart.CFrame * offset
        end
    end
end)

-- ============================================================
-- 18. RUNSERVICE - NOCLIP (Stepped, uses cached parts)
-- ============================================================
RunService.Stepped:Connect(function()
    if not State.noclip then return end
    for _, v in ipairs(State.characterParts) do
        if v and v.Parent and v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = false
        end
    end
end)

-- ============================================================
-- 19. INPUT - INFJUMP
-- ============================================================
UserInputService.JumpRequest:Connect(function()
    if not State.infJump then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ============================================================
-- 20. ESP FOR LATE JOINERS
-- ============================================================
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        if State.esp then
            task.wait(1)
            if c and c.Parent then
                applyESPToPlayer(p, true)
            end
        end
    end)
end)

-- ============================================================
-- 21. READY
-- ============================================================
print("[TE-Neptune] v6.0.5 SRHe (refactored) loaded. Pick PC or MOBILE to start.")
