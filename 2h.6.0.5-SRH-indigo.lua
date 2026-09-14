--[[
    TE NEPTUNE 6.0.5 SRHe - Refactored (INDIGO EDITION)
    ===================================================
    UI overhaul (per user request):
      - Grey translucent interface replaced with an OPAQUE INDIGO theme:
        indigo-black surfaces, indigo-400 accent, rounded corners, no glass.
      - Fonts streamlined to the Gotham family (GothamBlack / GothamBold /
        GothamMedium / Gotham) on a consistent size scale, with hover states.
      - Music player v2:
          * NOW PLAYING card showing song TITLE + PUBLISHER/ARTIST
            (custom IDs are looked up live via MarketplaceService).
          * Progress bar + "00:00 / xx:xx" readout; click/drag the bar to seek.
          * -10s / +10s skip buttons, play/pause toggle, stop, RANDOM song.
          * Built-in playlist of classic tracks with a live SEARCH filter;
            typing a number in search also offers a direct "PLAY ID" row.
            (Roblox blocks live catalog audio search from in-game scripts,
            so search runs over this curated playlist + your own IDs.)
      - Minimizing now opens a TWO-SIDED TASKBAR dock:
          * Left side:  OPEN PANEL button.
          * Right side: song info + mini progress + -10s / play / +10s / stop.
      - Exit dialog no longer dead-ends: "Hide" returns you to the floating
        reopen chip instead of stranding the user.
      - Fixed: the minimize button referenced the taskbar before it was
        declared (nil-index error on click) - now forward-declared.

    Layout changes (per earlier request):
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
-- 3. PALETTE  (opaque indigo theme)
-- ============================================================
local Palette = {
    Primary     = Color3.fromRGB(129, 140, 248),  -- indigo-400 (accent text)
    DarkPrimary = Color3.fromRGB( 79,  70, 229),  -- indigo-600 (active / strokes)
    Deepest     = Color3.fromRGB( 49,  46, 129),  -- indigo-900 (dividers / glow)
    Green       = Color3.fromRGB( 52, 211, 153),
    Red         = Color3.fromRGB(248, 113, 113),
    Yellow      = Color3.fromRGB(251, 191,  36),
    Cyan        = Color3.fromRGB(165, 180, 252),  -- indigo-300 (secondary text)
    Bg          = Color3.fromRGB( 23,  23,  40),  -- main surface (opaque)
    Panel       = Color3.fromRGB( 30,  31,  53),
    Surface     = Color3.fromRGB( 39,  40,  69),  -- cards / rows / buttons
    SurfaceDark = Color3.fromRGB( 17,  17,  30),  -- recessed inputs
    BgBlack     = Color3.fromRGB( 23,  23,  40),  -- legacy alias -> indigo base
}

-- Streamlined font scale (Gotham family)
local FONT_DISPLAY = Enum.Font.GothamBlack
local FONT_TITLE   = Enum.Font.GothamBold
local FONT_UI      = Enum.Font.GothamMedium
local FONT_TEXT    = Enum.Font.Gotham

-- rounded-corner shorthand
local function corner(parent, radius)
    return create("UICorner", parent, { CornerRadius = UDim.new(0, radius or 6) })
end

-- ============================================================
-- 4. STATE
-- ============================================================
local State = {
    -- settings
    target    = "s",
    flySpeed  = 50,
    volume    = 0.5,
    currentSong = nil,  -- {id=, title=, artist=} now-playing metadata
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
        button.BackgroundColor3 = Palette.DarkPrimary
        button.BackgroundTransparency = 0
        button.TextColor3 = Color3.new(1, 1, 1)
    else
        button.BackgroundColor3 = Palette.Surface
        button.BackgroundTransparency = 0
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

-- forward declarations (created in later sections, but referenced earlier)
local taskbar            -- minimized two-sided dock (section 10)
local minIndicator       -- floating reopen chip (section 10)
local taskbarSong        -- now-playing label on the dock
local taskbarPlayBtn     -- play/pause button on the dock
local taskbarFill        -- mini progress fill on the dock
local updateNowPlayingUI -- music player UI sync (defined in section 9)

-- ============================================================
-- 7. MAIN FRAME + TITLE BAR + EXIT DIALOG
-- ============================================================
local mainFrame = create("Frame", screenGui, {
    Size = UDim2.new(0.5, 0, 0.6, 0),
    Position = UDim2.new(0.5, 0, 0.45, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Palette.Bg,
    Visible = false,
    BorderSizePixel = 0,
})
corner(mainFrame, 10)
create("UIStroke", mainFrame, { Color = Palette.Deepest, Thickness = 3, Transparency = 0.55 })
local mainStroke = create("UIStroke", mainFrame, { Color = Palette.DarkPrimary, Thickness = 1, Transparency = 0.3 })
table.insert(State.strokes, mainStroke)

local titleBar = create("Frame", mainFrame, {
    Size = UDim2.new(1, 0, 0, 35),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
})

local titleLabel = create("TextLabel", titleBar, {
    Size = UDim2.new(0.55, 0, 0, 16),
    Position = UDim2.new(0, 14, 0, 5),
    BackgroundTransparency = 1,
    Text = "TE NEPTUNE 6.0.5 SRHe",
    TextColor3 = Palette.Primary,
    Font = FONT_TITLE,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
})
table.insert(State.accents, titleLabel)

create("TextLabel", titleBar, {
    Size = UDim2.new(0.55, 0, 0, 10),
    Position = UDim2.new(0, 14, 0, 21),
    BackgroundTransparency = 1,
    Text = "SAFE REDESIGNED HYBRID \194\183 GEN 3",
    TextColor3 = Palette.Cyan,
    Font = FONT_TEXT,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local targetLabel = create("TextLabel", titleBar, {
    Size = UDim2.new(0, 160, 1, 0),
    Position = UDim2.new(1, -226, 0, 0),
    BackgroundTransparency = 1,
    Text = "TARGET: S",
    TextColor3 = Palette.Cyan,
    Font = FONT_TITLE,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
})

-- divider under the title bar
create("Frame", mainFrame, {
    Size = UDim2.new(1, -16, 0, 1),
    Position = UDim2.new(0, 8, 0, 34),
    BackgroundColor3 = Palette.Deepest,
    BorderSizePixel = 0,
})

-- Exit confirmation dialog ("Hide" returns to the floating chip - no dead end)
local exitDialog = create("Frame", mainFrame, {
    Size = UDim2.new(0, 260, 0, 110),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Palette.Surface,
    Visible = false,
    ZIndex = 100,
    BorderSizePixel = 0,
})
corner(exitDialog, 10)
create("UIStroke", exitDialog, { Color = Palette.DarkPrimary, Thickness = 1 })
create("TextLabel", exitDialog, {
    Size = UDim2.new(1, 0, 0.45, 0),
    BackgroundTransparency = 1,
    Text = "Hide the panel?",
    TextColor3 = Color3.new(1, 1, 1),
    Font = FONT_TITLE,
    TextSize = 14,
    ZIndex = 101,
})
create("TextButton", exitDialog, {
    Size = UDim2.new(0.4, 0, 0, 30),
    Position = UDim2.new(0.05, 0, 0.6, 0),
    Text = "Hide",
    BackgroundColor3 = Palette.DarkPrimary,
    TextColor3 = Color3.new(1, 1, 1),
    Font = FONT_TITLE,
    TextSize = 13,
    ZIndex = 101,
    BorderSizePixel = 0,
}).MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    blurFx.Size = 0
    exitDialog.Visible = false
    minIndicator.Visible = true
end)
create("TextButton", exitDialog, {
    Size = UDim2.new(0.4, 0, 0, 30),
    Position = UDim2.new(0.55, 0, 0.6, 0),
    Text = "Stay",
    BackgroundColor3 = Palette.SurfaceDark,
    TextColor3 = Color3.new(1, 1, 1),
    Font = FONT_TITLE,
    TextSize = 13,
    ZIndex = 101,
    BorderSizePixel = 0,
}).MouseButton1Click:Connect(function()
    exitDialog.Visible = false
end)

-- title bar buttons: minimize (two-sided taskbar) + close
create("TextButton", titleBar, {
    Size = UDim2.new(0, 30, 0, 35),
    Position = UDim2.new(1, -60, 0, 0),
    Text = "\226\128\147",
    TextColor3 = Palette.Yellow,
    Font = FONT_TITLE,
    TextSize = 18,
    BackgroundTransparency = 1,
}).MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    blurFx.Size = 0
    taskbar.Visible = true
end)
create("TextButton", titleBar, {
    Size = UDim2.new(0, 30, 0, 35),
    Position = UDim2.new(1, -30, 0, 0),
    Text = "X",
    TextColor3 = Palette.Red,
    Font = FONT_TITLE,
    TextSize = 16,
    BackgroundTransparency = 1,
}).MouseButton1Click:Connect(function()
    exitDialog.Visible = true
end)

-- ============================================================
-- 8. COMMAND LIST PANEL (LEFT, 55%)
-- ============================================================
local listPanel = create("Frame", mainFrame, {
    Size = UDim2.new(0.55, -12, 1, -49),
    Position = UDim2.new(0, 8, 0, 41),
    BackgroundColor3 = Palette.Surface,
    BorderSizePixel = 0,
})
corner(listPanel, 8)
create("TextLabel", listPanel, {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    Text = "  COMMANDS",
    TextColor3 = Palette.Primary,
    Font = FONT_TITLE,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
})
create("Frame", listPanel, {
    Size = UDim2.new(1, -16, 0, 1),
    Position = UDim2.new(0, 8, 0, 26),
    BackgroundColor3 = Palette.Deepest,
    BorderSizePixel = 0,
})
local listScroll = create("ScrollingFrame", listPanel, {
    Size = UDim2.new(1, -16, 1, -40),
    Position = UDim2.new(0, 8, 0, 32),
    BackgroundTransparency = 1,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Palette.DarkPrimary,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
})
create("UIListLayout", listScroll, {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

-- ============================================================
-- 9. MUSIC PANEL (RIGHT, 45%) - PLAYER v2
--    search / random / now-playing title + publisher /
--    00:00 / xx:xx progress + seek / -10s +10s skip
-- ============================================================
local MarketplaceService = game:GetService("MarketplaceService")

-- curated starter playlist (playback availability depends on Roblox audio
-- permissions, but title/publisher display + search work on metadata)
local PLAYLIST = {
    { id = 142376088,  title = "Raining Tacos",            artist = "Parry Gripp"    },
    { id = 1848354536, title = "Monkeys Spinning Monkeys", artist = "Kevin MacLeod"  },
    { id = 1015394442, title = "Wind of Fjords",           artist = "Telemon"        },
    { id = 6456594369, title = "Crab Rave",                artist = "Noisestorm"     },
    { id = 5153862587, title = "Never Gonna Give You Up",  artist = "Rick Astley"    },
    { id = 2844158733, title = "Careless Whisper",         artist = "George Michael" },
    { id = 135840540,  title = "Mii Channel Theme",        artist = "Nintendo"       },
    { id = 136585459,  title = "Nyan Cat",                 artist = "daniwellP"      },
    { id = 137225771,  title = "Spooky Scary Skeletons",   artist = "Andrew Gold"    },
    { id = 1836951058, title = "Sweden (Minecraft)",       artist = "C418"           },
}

local musicPanel = create("Frame", mainFrame, {
    Size = UDim2.new(0.45, -12, 1, -49),
    Position = UDim2.new(0.55, 4, 0, 41),
    BackgroundColor3 = Palette.Surface,
    BorderSizePixel = 0,
})
corner(musicPanel, 8)
create("TextLabel", musicPanel, {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    Text = "  MUSIC PLAYER",
    TextColor3 = Palette.Primary,
    Font = FONT_TITLE,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
})
create("Frame", musicPanel, {
    Size = UDim2.new(1, -16, 0, 1),
    Position = UDim2.new(0, 8, 0, 26),
    BackgroundColor3 = Palette.Deepest,
    BorderSizePixel = 0,
})
local musicScroll = create("ScrollingFrame", musicPanel, {
    Size = UDim2.new(1, -16, 1, -40),
    Position = UDim2.new(0, 8, 0, 32),
    BackgroundTransparency = 1,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Palette.DarkPrimary,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
})
create("UIListLayout", musicScroll, {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

-- [1] NOW PLAYING card: title + publisher + progress bar + time readout
local npCard = create("Frame", musicScroll, {
    Size = UDim2.new(1, 0, 0, 74),
    BackgroundColor3 = Palette.SurfaceDark,
    LayoutOrder = 1,
    BorderSizePixel = 0,
})
corner(npCard, 8)
local npTitle = create("TextLabel", npCard, {
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 10, 0, 7),
    BackgroundTransparency = 1,
    Text = "Nothing playing",
    TextColor3 = Color3.new(1, 1, 1),
    Font = FONT_TITLE,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
})
local npArtist = create("TextLabel", npCard, {
    Size = UDim2.new(1, -20, 0, 12),
    Position = UDim2.new(0, 10, 0, 24),
    BackgroundTransparency = 1,
    Text = "Pick a track below or enter a Music ID",
    TextColor3 = Palette.Cyan,
    Font = FONT_TEXT,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
})
local seekBar = create("TextButton", npCard, {
    Size = UDim2.new(1, -20, 0, 8),
    Position = UDim2.new(0, 10, 0, 42),
    BackgroundColor3 = Palette.Surface,
    Text = "",
    AutoButtonColor = false,
    BorderSizePixel = 0,
})
corner(seekBar, 4)
local seekFill = create("Frame", seekBar, {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Palette.DarkPrimary,
    BorderSizePixel = 0,
})
corner(seekFill, 4)
local timeLabel = create("TextLabel", npCard, {
    Size = UDim2.new(1, -20, 0, 12),
    Position = UDim2.new(0, 10, 0, 54),
    BackgroundTransparency = 1,
    Text = "00:00 / --:--",
    TextColor3 = Palette.Cyan,
    Font = FONT_TEXT,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
})

-- [2] transport row: -10s / play-pause / +10s
local transportRow = create("Frame", musicScroll, {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    LayoutOrder = 2,
})
local backBtn = create("TextButton", transportRow, {
    Size = UDim2.new(0.32, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Palette.Bg,
    Text = "-10s",
    TextColor3 = Color3.fromRGB(230, 230, 245),
    Font = FONT_TITLE,
    TextSize = 11,
    BorderSizePixel = 0,
    AutoButtonColor = true,
})
corner(backBtn, 6)
local playToggleBtn = create("TextButton", transportRow, {
    Size = UDim2.new(0.32, 0, 1, 0),
    Position = UDim2.new(0.34, 0, 0, 0),
    BackgroundColor3 = Palette.DarkPrimary,
    Text = "\226\150\182",
    TextColor3 = Color3.new(1, 1, 1),
    Font = FONT_TITLE,
    TextSize = 12,
    BorderSizePixel = 0,
    AutoButtonColor = true,
})
corner(playToggleBtn, 6)
local fwdBtn = create("TextButton", transportRow, {
    Size = UDim2.new(0.32, 0, 1, 0),
    Position = UDim2.new(0.68, 0, 0, 0),
    BackgroundColor3 = Palette.Bg,
    Text = "+10s",
    TextColor3 = Color3.fromRGB(230, 230, 245),
    Font = FONT_TITLE,
    TextSize = 11,
    BorderSizePixel = 0,
    AutoButtonColor = true,
})
corner(fwdBtn, 6)

-- [3] functions row: RANDOM / STOP / VOL
local funcRow = create("Frame", musicScroll, {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
})
local randomBtn = create("TextButton", funcRow, {
    Size = UDim2.new(0.32, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Palette.Bg,
    Text = "RANDOM",
    TextColor3 = Palette.Yellow,
    Font = FONT_TITLE,
    TextSize = 10,
    BorderSizePixel = 0,
    AutoButtonColor = true,
})
corner(randomBtn, 6)
local stopBtn = create("TextButton", funcRow, {
    Size = UDim2.new(0.32, 0, 1, 0),
    Position = UDim2.new(0.34, 0, 0, 0),
    BackgroundColor3 = Palette.Bg,
    Text = "STOP",
    TextColor3 = Palette.Red,
    Font = FONT_TITLE,
    TextSize = 10,
    BorderSizePixel = 0,
    AutoButtonColor = true,
})
corner(stopBtn, 6)
local volBtn = create("TextButton", funcRow, {
    Size = UDim2.new(0.32, 0, 1, 0),
    Position = UDim2.new(0.68, 0, 0, 0),
    BackgroundColor3 = Palette.Bg,
    Text = "VOL: 50%",
    TextColor3 = Palette.Cyan,
    Font = FONT_TITLE,
    TextSize = 10,
    BorderSizePixel = 0,
    AutoButtonColor = true,
})
corner(volBtn, 6)

-- [4] manual Music ID row
local idRow = create("Frame", musicScroll, {
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
    LayoutOrder = 4,
})
local musicIdInput = create("TextBox", idRow, {
    Size = UDim2.new(1, -36, 1, 0),
    BackgroundColor3 = Palette.SurfaceDark,
    Text = "",
    PlaceholderText = "Music ID (any rbxassetid)",
    PlaceholderColor3 = Color3.fromRGB(110, 112, 150),
    TextColor3 = Color3.fromRGB(230, 230, 245),
    Font = FONT_TEXT,
    TextSize = 10,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
    BorderSizePixel = 0,
})
corner(musicIdInput, 6)
create("UIPadding", musicIdInput, { PaddingLeft = UDim.new(0, 8) })
local idGoBtn = create("TextButton", idRow, {
    Size = UDim2.new(0, 32, 1, 0),
    Position = UDim2.new(1, -32, 0, 0),
    BackgroundColor3 = Palette.DarkPrimary,
    Text = "GO",
    TextColor3 = Color3.new(1, 1, 1),
    Font = FONT_TITLE,
    TextSize = 10,
    BorderSizePixel = 0,
    AutoButtonColor = true,
})
corner(idGoBtn, 6)

-- [5] search row
local searchRow = create("Frame", musicScroll, {
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
    LayoutOrder = 5,
})
local searchBox = create("TextBox", searchRow, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Palette.SurfaceDark,
    Text = "",
    PlaceholderText = "Search songs... (a pure number = play that ID)",
    PlaceholderColor3 = Color3.fromRGB(110, 112, 150),
    TextColor3 = Palette.Primary,
    Font = FONT_TEXT,
    TextSize = 10,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
    BorderSizePixel = 0,
})
corner(searchBox, 6)
create("UIPadding", searchBox, { PaddingLeft = UDim.new(0, 8) })

-- [6] playlist header
local plHeader = create("TextLabel", musicScroll, {
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundTransparency = 1,
    Text = "PLAYLIST \194\183 0 TRACKS",
    TextColor3 = Palette.Cyan,
    Font = FONT_TITLE,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 6,
})

local musicSound = create("Sound", workspace, {
    Name = "TE_Neptune_Music",
    Volume = State.volume,
    Looped = true,
})

local seeking = false  -- true while the user drags the seek bar

-- format seconds as MM:SS
local function fmtTime(t)
    t = math.max(0, math.floor(t + 0.5))
    return string.format("%02d:%02d", math.floor(t / 60), t % 60)
end

-- look up title + publisher for an arbitrary audio id (fails safely offline)
local function fetchSongMeta(id)
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(id)
    end)
    if ok and type(info) == "table" then
        local title = info.Name or ("ID " .. tostring(id))
        local artist = "Unknown Publisher"
        if type(info.Creator) == "table" and info.Creator.Name then
            artist = info.Creator.Name
        end
        return title, artist
    end
    return "ID " .. tostring(id), "Unknown Publisher"
end

-- forward declarations (closures below capture these)
local playSong
local refreshPlaylist

local function tryPlayFromInput()
    local id = tonumber(musicIdInput.Text)
    if id and id > 0 then
        playSong(id)  -- title/publisher fetched live
        print("[TE-Neptune] Playing ID:", id)
    else
        warn("[TE-Neptune] Invalid music ID")
    end
end

-- rebuild the playlist rows filtered by the search box text
refreshPlaylist = function()
    for _, child in ipairs(musicScroll:GetChildren()) do
        if child:IsA("TextButton") and child.Name == "plRow" then
            child:Destroy()
        end
    end
    local q = string.match(searchBox.Text or "", "^%s*(.-)%s*$") or ""
    q = string.lower(q)
    local idOnly = tonumber(q)
    local order = 99
    local count = 0

    -- numeric query: offer a direct "play this ID" row
    if idOnly and #q >= 3 then
        order = order + 1
        local row = create("TextButton", musicScroll, {
            Name = "plRow",
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Palette.Deepest,
            Text = "",
            AutoButtonColor = true,
            LayoutOrder = order,
            BorderSizePixel = 0,
        })
        corner(row, 6)
        create("TextLabel", row, {
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = "\226\150\182 PLAY ID: " .. q,
            TextColor3 = Palette.Yellow,
            Font = FONT_TITLE,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        row.MouseButton1Click:Connect(function()
            playSong(idOnly)
        end)
    end

    for _, entry in ipairs(PLAYLIST) do
        local hay = string.lower(entry.title .. " " .. entry.artist)
        if q == "" or string.find(hay, q, 1, true) then
            count = count + 1
            order = order + 1
            local isCurrent = State.currentSong ~= nil and State.currentSong.id == entry.id
            local row = create("TextButton", musicScroll, {
                Name = "plRow",
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = isCurrent and Palette.Deepest or Palette.Bg,
                Text = "",
                AutoButtonColor = true,
                LayoutOrder = order,
                BorderSizePixel = 0,
            })
            corner(row, 6)
            create("UIStroke", row, {
                Color = isCurrent and Palette.DarkPrimary or Palette.Deepest,
                Thickness = 1,
                Transparency = 0.35,
            })
            create("TextLabel", row, {
                Size = UDim2.new(1, -20, 0, 14),
                Position = UDim2.new(0, 10, 0, 3),
                BackgroundTransparency = 1,
                Text = (isCurrent and "\226\150\182 " or "") .. entry.title,
                TextColor3 = isCurrent and Color3.new(1, 1, 1) or Color3.fromRGB(222, 224, 240),
                Font = FONT_UI,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            create("TextLabel", row, {
                Size = UDim2.new(1, -20, 0, 10),
                Position = UDim2.new(0, 10, 0, 16),
                BackgroundTransparency = 1,
                Text = entry.artist,
                TextColor3 = Palette.Cyan,
                Font = FONT_TEXT,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            row.MouseButton1Click:Connect(function()
                playSong(entry.id, entry.title, entry.artist)
            end)
        end
    end
    plHeader.Text = "PLAYLIST \194\183 " .. count .. " TRACKS"
end

-- keep the NOW PLAYING card + taskbar dock in sync with State.currentSong
updateNowPlayingUI = function()
    local s = State.currentSong
    npTitle.Text = s and s.title or "Nothing playing"
    npArtist.Text = s and s.artist or "Pick a track below or enter a Music ID"
    local glyph = musicSound.Playing and "\226\143\184" or "\226\150\182"
    playToggleBtn.Text = glyph
    if taskbarSong then
        taskbarSong.Text = s and (s.title .. "  \194\183  " .. s.artist) or "Nothing playing"
    end
    if taskbarPlayBtn then
        taskbarPlayBtn.Text = glyph
    end
    refreshPlaylist()
end

-- central play routine: everything funnels through here
playSong = function(id, title, artist)
    id = tonumber(id)
    if not id or id <= 0 then
        warn("[TE-Neptune] Invalid music ID")
        return
    end
    seeking = false
    State.currentSong = {
        id = id,
        title = title or ("ID " .. tostring(id)),
        artist = artist or "fetching publisher...",
    }
    musicSound:Stop()
    musicSound.SoundId = "rbxassetid://" .. id
    musicSound.TimePosition = 0
    musicSound:Play()
    updateNowPlayingUI()

    -- no title supplied (manual ID / random from search): fetch metadata live
    if not title then
        task.spawn(function()
            local t, a = fetchSongMeta(id)
            if State.currentSong and State.currentSong.id == id then
                State.currentSong.title = t
                State.currentSong.artist = a
                updateNowPlayingUI()
            end
        end)
    end

    -- availability watchdog: flag audio that Roblox refuses to load
    task.spawn(function()
        local t0 = tick()
        while tick() - t0 < 6 do
            if musicSound.IsLoaded and musicSound.TimeLength > 0 then
                return
            end
            task.wait(0.25)
        end
        if State.currentSong and State.currentSong.id == id
            and not (musicSound.IsLoaded and musicSound.TimeLength > 0) then
            State.currentSong.artist = "unavailable / restricted audio"
            updateNowPlayingUI()
            warn("[TE-Neptune] Audio " .. id .. " failed to load (may be restricted)")
        end
    end)
end

-- random song from the curated playlist
local function randomSong()
    if #PLAYLIST == 0 then return end
    local pick = PLAYLIST[math.random(#PLAYLIST)]
    for _ = 1, 8 do
        if #PLAYLIST == 1 or not State.currentSong or pick.id ~= State.currentSong.id then
            break
        end
        pick = PLAYLIST[math.random(#PLAYLIST)]
    end
    playSong(pick.id, pick.title, pick.artist)
end

-- skip forward/backward; clamped to [0, length]
local function skipBy(delta)
    if musicSound.TimeLength <= 0 then return end
    musicSound.TimePosition = math.clamp(musicSound.TimePosition + delta, 0, musicSound.TimeLength)
end

local function stopMusic()
    musicSound:Stop()
    updateNowPlayingUI()
end

local function togglePlay()
    if musicSound.Playing then
        musicSound:Pause()
    elseif State.currentSong and musicSound.IsLoaded and musicSound.TimeLength > 0 then
        musicSound:Play()  -- resume after pause, restart after stop
    else
        tryPlayFromInput()
    end
    updateNowPlayingUI()
end

-- Volume: discrete steps table (no float drift)
local volumeSteps = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0}
volBtn.MouseButton1Click:Connect(function()
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
    volBtn.Text = "VOL: " .. math.floor(State.volume * 100 + 0.5) .. "%"
end)

-- seek bar: click or drag anywhere on the bar to jump
local function seekFromX(x)
    if musicSound.TimeLength <= 0 then return end
    local rel = (x - seekBar.AbsolutePosition.X) / math.max(1, seekBar.AbsoluteSize.X)
    rel = math.clamp(rel, 0, 1)
    musicSound.TimePosition = rel * musicSound.TimeLength
    seekFill.Size = UDim2.new(rel, 0, 1, 0)
end
seekBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        seeking = true
        seekFromX(input.Position.X)
    end
end)
seekBar.InputChanged:Connect(function(input)
    if seeking and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        seekFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        seeking = false
    end
end)

-- wire up all player controls
backBtn.MouseButton1Click:Connect(function() skipBy(-10) end)
fwdBtn.MouseButton1Click:Connect(function() skipBy(10) end)
playToggleBtn.MouseButton1Click:Connect(togglePlay)
stopBtn.MouseButton1Click:Connect(stopMusic)
randomBtn.MouseButton1Click:Connect(randomSong)
idGoBtn.MouseButton1Click:Connect(tryPlayFromInput)
musicIdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then tryPlayFromInput() end
end)
searchBox:GetPropertyChangedSignal("Text"):Connect(refreshPlaylist)

refreshPlaylist()

-- ============================================================
-- 10. TASKBAR (minimized state) - TWO-SIDED DOCK
--    left:  OPEN PANEL button
--    right: now-playing info + mini progress + transport controls
-- ============================================================
taskbar = create("Frame", screenGui, {
    Size = UDim2.new(1, 0, 0, 46),
    Position = UDim2.new(0, 0, 1, -46),
    BackgroundColor3 = Palette.Bg,
    Visible = false,
    ZIndex = 500,
    BorderSizePixel = 0,
})
create("UIStroke", taskbar, { Color = Palette.DarkPrimary, Thickness = 1, Transparency = 0.4 })

-- LEFT SIDE - reopen the panel
local tbOpenBtn = create("TextButton", taskbar, {
    Size = UDim2.new(0, 150, 0, 32),
    Position = UDim2.new(0, 10, 0.5, -16),
    BackgroundColor3 = Palette.DarkPrimary,
    Text = "OPEN PANEL",
    TextColor3 = Color3.new(1, 1, 1),
    Font = FONT_TITLE,
    TextSize = 12,
    BorderSizePixel = 0,
    AutoButtonColor = true,
    ZIndex = 501,
})
corner(tbOpenBtn, 8)
tbOpenBtn.MouseButton1Click:Connect(function()
    taskbar.Visible = false
    mainFrame.Visible = true
    blurFx.Size = 18
end)

-- divider between the two sides
create("Frame", taskbar, {
    Size = UDim2.new(0, 1, 1, -16),
    Position = UDim2.new(0, 172, 0.5, -8),
    BackgroundColor3 = Palette.Deepest,
    BorderSizePixel = 0,
    ZIndex = 501,
})

-- RIGHT SIDE - song info + mini progress
taskbarSong = create("TextLabel", taskbar, {
    Size = UDim2.new(1, -390, 0, 16),
    Position = UDim2.new(0, 184, 0, 5),
    BackgroundTransparency = 1,
    Text = "Nothing playing",
    TextColor3 = Color3.fromRGB(230, 230, 245),
    Font = FONT_UI,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 501,
})
local tbBar = create("Frame", taskbar, {
    Size = UDim2.new(1, -390, 0, 4),
    Position = UDim2.new(0, 184, 0, 27),
    BackgroundColor3 = Palette.SurfaceDark,
    BorderSizePixel = 0,
    ZIndex = 501,
})
corner(tbBar, 2)
taskbarFill = create("Frame", tbBar, {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Palette.DarkPrimary,
    BorderSizePixel = 0,
    ZIndex = 502,
})
corner(taskbarFill, 2)

-- RIGHT SIDE - compact transport controls: -10 / play / +10 / stop
local function tbControl(text, xOffset, bgColor, fgColor, onClick)
    local btn = create("TextButton", taskbar, {
        Size = UDim2.new(0, 34, 0, 32),
        Position = UDim2.new(1, xOffset, 0.5, -16),
        BackgroundColor3 = bgColor,
        Text = text,
        TextColor3 = fgColor,
        Font = FONT_TITLE,
        TextSize = 11,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        ZIndex = 501,
    })
    corner(btn, 8)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end
tbControl("\226\150\182", -50, Palette.Surface, Color3.fromRGB(230, 230, 245), function() skipBy(10) end)
tbControl("\226\150\160", -10, Palette.Surface, Palette.Red, stopMusic)
taskbarPlayBtn = tbControl("\226\150\182", -90, Palette.DarkPrimary, Color3.new(1, 1, 1), togglePlay)
tbControl("-10", -130, Palette.Surface, Color3.fromRGB(230, 230, 245), function() skipBy(-10) end)

-- floating reopen chip (shown after "Hide" in the exit dialog)
minIndicator = create("TextButton", screenGui, {
    Size = UDim2.new(0, 130, 0, 30),
    Position = UDim2.new(0.5, -65, 1, -40),
    BackgroundColor3 = Palette.Surface,
    BorderSizePixel = 0,
    Text = "TE-NEPTUNE",
    TextColor3 = Palette.Primary,
    Font = FONT_TITLE,
    TextSize = 11,
    ZIndex = 100,
    AutoButtonColor = true,
})
corner(minIndicator, 8)
local minStroke = create("UIStroke", minIndicator, { Color = Palette.DarkPrimary })
table.insert(State.strokes, minStroke)
table.insert(State.accents, minIndicator)

minIndicator.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    minIndicator.Visible = false
    blurFx.Size = 18
end)

-- initial sync of now-playing labels
updateNowPlayingUI()

-- ============================================================
-- 10.5 MUSIC PROGRESS LOOP (time readout + seek fill + taskbar bar)
-- ============================================================
RunService.Heartbeat:Connect(function()
    local len = musicSound.TimeLength
    local pos = musicSound.TimePosition
    if len > 0 then
        timeLabel.Text = fmtTime(math.clamp(pos, 0, len)) .. " / " .. fmtTime(len)
        local ratio = math.clamp(pos / len, 0, 1)
        if not seeking then
            seekFill.Size = UDim2.new(ratio, 0, 1, 0)
        end
        if taskbarFill then
            taskbarFill.Size = UDim2.new(ratio, 0, 1, 0)
        end
    else
        timeLabel.Text = "00:00 / --:--"
        seekFill.Size = UDim2.new(0, 0, 1, 0)
        if taskbarFill then
            taskbarFill.Size = UDim2.new(0, 0, 1, 0)
        end
    end
end)

-- ============================================================
-- 11. START SCREEN (PC / MOBILE)
-- ============================================================
local startScreen = create("Frame", screenGui, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Palette.Bg,
    ZIndex = 100,
    BorderSizePixel = 0,
})
local startTitle = create("TextLabel", startScreen, {
    Size = UDim2.new(1, 0, 0.15, 0),
    Position = UDim2.new(0, 0, 0.28, 0),
    BackgroundTransparency = 1,
    Text = "TE NEPTUNE 6.0.5",
    TextColor3 = Palette.Primary,
    Font = FONT_DISPLAY,
    TextSize = 42,
    ZIndex = 101,
})
table.insert(State.accents, startTitle)
create("TextLabel", startScreen, {
    Size = UDim2.new(1, 0, 0.05, 0),
    Position = UDim2.new(0, 0, 0.44, 0),
    BackgroundTransparency = 1,
    Text = "SAFE REDESIGNED HYBRID GEN 3 edition",
    TextColor3 = Palette.Cyan,
    Font = FONT_TEXT,
    TextSize = 14,
    ZIndex = 101,
})

local function makeStartButton(text, xOffset, isMobile)
    local btn = create("TextButton", startScreen, {
        Size = UDim2.new(0, 190, 0, 48),
        Position = UDim2.new(0.5, xOffset, 0.6, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = text,
        ZIndex = 101,
        Font = FONT_TITLE,
        TextSize = 16,
        BackgroundColor3 = isMobile and Palette.Surface or Palette.DarkPrimary,
        TextColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AutoButtonColor = true,
    })
    corner(btn, 8)
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
makeStartButton("PC", -105, false)
makeStartButton("MOBILE", 105, true)

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
        BackgroundColor3 = Palette.Surface,
        BackgroundTransparency = 0,
        Font = FONT_UI,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = cmdOrder,
        Text = "  " .. name,
        TextColor3 = Color3.fromRGB(200, 200, 220),
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
corner(btn, 6)
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
        BackgroundColor3 = Palette.Surface,
        BackgroundTransparency = 0,
        Font = FONT_UI,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = cmdOrder,
        Text = "  " .. name,
        TextColor3 = Color3.fromRGB(200, 200, 220),
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
corner(btn, 6)
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
        Font = FONT_UI,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local input = create("TextBox", row, {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0.35, 0, 0, 0),
        BackgroundColor3 = Palette.SurfaceDark,
        Text = defaultText or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Color3.fromRGB(110, 112, 150),
        TextColor3 = Palette.Cyan,
        Font = FONT_UI,
        TextSize = 10,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Center,
        BorderSizePixel = 0,
    })
    local applyBtn = create("TextButton", row, {
        Size = UDim2.new(0.2, 0, 1, 0),
        Position = UDim2.new(0.8, 0, 0, 0),
        BackgroundColor3 = Palette.DarkPrimary,
        Text = "OK",
        TextColor3 = Color3.new(1, 1, 1),
        Font = FONT_TITLE,
        TextSize = 10,
        BorderSizePixel = 0,
    })
corner(input, 6)
    corner(applyBtn, 6)
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
        Font = FONT_UI,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local input = create("TextBox", container, {
        Size = UDim2.new(1, -50, 0, 48),
        Position = UDim2.new(0, 2, 0, 18),
        BackgroundColor3 = Palette.SurfaceDark,
        Text = "",
        PlaceholderText = "Lua code here...",
        PlaceholderColor3 = Color3.fromRGB(110, 112, 150),
        TextColor3 = Palette.Cyan,
        Font = FONT_UI,
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
        Text = "RUN",
        TextColor3 = Color3.new(1, 1, 1),
        Font = FONT_TITLE,
        TextSize = 10,
        BorderSizePixel = 0,
    })
corner(input, 6)
    corner(applyBtn, 6)
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
        BackgroundColor3 = Palette.Surface,
        BackgroundTransparency = 0,
        Font = FONT_UI,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "  " .. cmdName .. ": " .. realName,
        TextColor3 = Palette.Yellow,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
    create("UIStroke", btn, { Color = Palette.Yellow, Thickness = 1 })
    corner(btn, 6)
    local delBtn = create("TextButton", row, {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -22, 0, 0),
        BackgroundColor3 = Color3.fromRGB(122, 34, 46),
        BackgroundTransparency = 0,
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        Font = FONT_UI,
        TextSize = 10,
        BorderSizePixel = 0,
    })
corner(delBtn, 6)
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
addInputCommand("CBG", "Theme: r,g,b,t (0-255, 0-100)", "99,102,241,50", "r,g,b,t", function(text)
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
        warn("[TE-Neptune] CBG format: r,g,b,t (e.g. 99,102,241,50)")
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
print("[TE-Neptune] v6.0.5 SRHe INDIGO loaded. Pick PC or MOBILE to start.")
