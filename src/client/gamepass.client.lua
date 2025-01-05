local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- Create a GUI for gamepasses
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GamepassGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

local gamepassFrame = Instance.new("Frame")
gamepassFrame.Size = UDim2.new(0.2, 0, 0.6, 0)
gamepassFrame.Position = UDim2.new(0.8, 0, 0.2, 0)
gamepassFrame.BackgroundTransparency = 1 -- Make the frame background invisible
gamepassFrame.Parent = screenGui

-- Define your gamepasses
local gamepasses = {
    {Id = 1022581009, Name = "Unlock All Levels"}, -- Replace with your gamepass IDs
    {Id = 1022595197, Name = "Unlock All Marbles"},
}

-- Function to create a button for each gamepass
local function createGamepassButton(gamepass)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 60) -- Circular buttons (Width = Height)
    button.Position = UDim2.new(0.5, 0, (#gamepassFrame:GetChildren() - 1) * 0.2, 0) -- Space buttons vertically
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 200) -- Blue color
    button.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    button.Text = gamepass.Name
    button.Parent = gamepassFrame
    button.BorderSizePixel = 0 -- Remove border for a clean look

    -- Make the button circular
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0) -- Fully circular
    uiCorner.Parent = button

    -- On click, prompt purchase
    button.MouseButton1Click:Connect(function()
        MarketplaceService:PromptGamePassPurchase(player, gamepass.Id)
    end)
end

-- Create buttons for each gamepass
for _, gamepass in ipairs(gamepasses) do
    createGamepassButton(gamepass)
end
