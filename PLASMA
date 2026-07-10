-- [[ TE-PLASMA 6.0 GENERATION 2 ]]
local CoreGui = game:GetService("CoreGui")

if CoreGui:FindFirstChild("TE_PLASMA_6_GEN2") then
    CoreGui.TE_PLASMA_6_GEN2:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "TE_PLASMA_6_GEN2"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Colors
local Purple = Color3.fromRGB(170, 0, 255)

-- Main TextBox (The flashing line)
local MainBox = Instance.new("TextBox", ScreenGui)
MainBox.Size = UDim2.new(0, 400, 0, 30)
MainBox.Position = UDim2.new(0.5, -200, 0.5, -15)
MainBox.BackgroundTransparency = 1
MainBox.Font = Enum.Font.Code
MainBox.TextSize = 24
MainBox.TextColor3 = Purple
MainBox.TextStrokeColor3 = Color3.fromRGB(50, 0, 75)
MainBox.TextStrokeTransparency = 0.5
MainBox.Text = "TE-PLASMA 6.0 GENERATION 2"
MainBox.ClearTextOnFocus = false
MainBox.TextWrapped = false

-- List Container (Appears below)
local ListContainer = Instance.new("Frame", ScreenGui)
ListContainer.Size = UDim2.new(0, 400, 0, 150)
ListContainer.Position = UDim2.new(0.5, -200, 0.5, 25)
ListContainer.BackgroundTransparency = 1
ListContainer.Visible = false

local Layout = Instance.new("UIListLayout", ListContainer)
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Script Links
local Scripts = {
    [1] = "https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/list-9k9wste1-2",
    [2] = "https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/list-ute2",
    [3] = "https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/list-ute3-01",
    [4] = "https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/list-ute4legacygui",
    [5] = "https://raw.githubusercontent.com/sorta-onYOUTUBE/ute3release/refs/heads/main/sTE%205R"
}

-- Creating the 5 Purple Lines
local Names = {"1: 1.2", "2: 2.0", "3: 3.0.1", "4: 4.0", "5: 5R"}

for i = 1, 5 do
    local line = Instance.new("TextButton", ListContainer)
    line.Size = UDim2.new(0, 400, 0, 25)
    line.BackgroundTransparency = 1
    line.Font = Enum.Font.Code
    line.TextSize = 20
    line.TextColor3 = Purple
    line.TextStrokeColor3 = Color3.fromRGB(50, 0, 75)
    line.TextStrokeTransparency = 0.5
    line.Text = Names[i]
    line.AutoButtonColor = false
    
    -- Keep the click functionality as a bonus
    line.MouseButton1Click:Connect(function()
        pcall(function()
            loadstring(game:HttpGet(Scripts[i]))()
        end)
    end)
end

-- Flashing & Input Logic
local isFocused = false

MainBox.Focused:Connect(function()
    isFocused = true
    MainBox.Text = "" -- Clear placeholder so user can type
end)

MainBox.FocusLost:Connect(function(enter)
    isFocused = false
    if enter then
        -- Clean up the input (remove spaces, make lowercase)
        local input = string.lower(string.gsub(MainBox.Text, "%s+", ""))
        
        if input == "list" then
            ListContainer.Visible = true
        elseif input == "0" or input == "unlist" then
            ListContainer.Visible = false
        elseif tonumber(input) and Scripts[tonumber(input)] then
            -- If they type 1-5, execute the script
            pcall(function()
                loadstring(game:HttpGet(Scripts[tonumber(input)]))()
            end)
        end
        
        MainBox.Text = "" -- Clear text so flashing resumes
    end
end)

-- Flashing Loop
task.spawn(function()
    local showList = true
    while true do
        if not isFocused and MainBox.Text == "" then
            MainBox.Text = showList and "Type list." or "TE-PLASMA 6.0 GENERATION 2"
            showList = not showList
        end
        task.wait(1)
    end
end)
