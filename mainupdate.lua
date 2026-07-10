local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "LATEST TROLL EMs | LOADER",
    LoadingTitle = "Hello, user!",
    LoadingSubtitle = "Select your interface style",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local Tab = Window:CreateTab("Library Select", 4483362458)

Tab:CreateSection("Choose Your GUI Style")

-- [[ 6.0.1 ]] --
Tab:CreateButton({
    Name = "TE ULTIMATUM 6.0.1",
    Callback = function()
        Rayfield:Notify({Title = "Loading...", Content = "Executing ULTIMATUM", Duration = 3})
        Rayfield:Destroy() -- Closes loader
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/TE%20ULTIMATUM%206.0.1"))()
    end,
})

Tab:CreateLabel("The most powerful Troll em script.")

-- [[ PLASMA GUI BUTTON ]] --
Tab:CreateButton({
    Name = "PLASMA GEN 2 (The whole GEN 1 powerful library in one go.)",
    Callback = function()
        Rayfield:Notify({Title = "Loading...", Content = "Executing TE PLASMA 6", Duration = 3})
        Rayfield:Destroy() -- Closes loader
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/PLASMA"))()
    end,
})

Tab:CreateLabel("The whole library.")

-- [[ INFO FOOTER ]] --
Tab:CreateSection("Information")
Tab:CreateParagraph("Credits", "Created by 9k9w. All scripts and hub links are included in both versions.")

Rayfield:Notify({
    Title = "Welcome",
    Content = "Select a library to begin exploiting.",
    Duration = 5,
    Image = 4483362458,
})
