-- [[ ULTIMATE TROLL EM 4.0 - UNIVERSAL LOADER ]] --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "ULTIMATE TROLL EM 4.0 | LOADER",
    LoadingTitle = "Hello, user!",
    LoadingSubtitle = "Select your interface style",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local Tab = Window:CreateTab("Library Select", 4483362458)

Tab:CreateSection("Choose Your GUI Style")

-- [[ LEGACY GUI BUTTON ]] --
Tab:CreateButton({
    Name = "LEGACY (Custom Gray Tiles)",
    Callback = function()
        Rayfield:Notify({Title = "Loading...", Content = "Executing Legacy Interface", Duration = 3})
        Rayfield:Destroy() -- Closes loader
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/list-ute4legacygui"))()
    end,
})

Tab:CreateLabel("Classic rectangular tiles with console and greeting.")

-- [[ RAYFIELD GUI BUTTON ]] --
Tab:CreateButton({
    Name = "RAYFIELD (Modern Tabs/Sliders)",
    Callback = function()
        Rayfield:Notify({Title = "Loading...", Content = "Executing Rayfield Interface", Duration = 3})
        Rayfield:Destroy() -- Closes loader
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/list-ute4rayfield"))()
    end,
})

Tab:CreateLabel("Modern Sirius-style UI with organized categories.")

-- [[ INFO FOOTER ]] --
Tab:CreateSection("Information")
Tab:CreateParagraph("Credits", "Created by Seraphic. All scripts and hub links are included in both versions.")

Rayfield:Notify({
    Title = "Welcome",
    Content = "Select a library to begin trolling.",
    Duration = 5,
    Image = 4483362458,
})
