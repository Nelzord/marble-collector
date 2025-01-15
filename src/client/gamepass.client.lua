local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- Define your gamepasses with their PNG image asset IDs and descriptions
local gamepasses = {
    {Id = 1032168456, Name = "VIP", Image = "rbxassetid://135437859595427", Description = "Get exclusive VIP perks!"},
    {Id = 1022581009, Name = "Unlock All Levels", Image = "rbxassetid://77456133345078", Description = "Unlock all levels instantly!"},
    {Id = 1022595197, Name = "Unlock All Marbles", Image = "rbxassetid://75022979826223", Description = "Gain access to all marbles!"},
}

-- Function to create the GUI for gamepasses
local function createGamepassGui()
    -- Remove any existing GUI to avoid duplication
    local existingGui = player:FindFirstChild("PlayerGui"):FindFirstChild("GamepassGui")
    if existingGui then
        existingGui:Destroy()
    end

    -- Create a new GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GamepassGui"
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local gamepassFrame = Instance.new("Frame")
    gamepassFrame.Size = UDim2.new(0.2, 0, 0.6, 0)
    gamepassFrame.Position = UDim2.new(0.85, 0, 0.35, 0)
    gamepassFrame.BackgroundTransparency = 1
    gamepassFrame.Parent = screenGui

    -- Function to create a button for each gamepass
    local function createGamepassButton(gamepass)
        local button = Instance.new("ImageButton")
        button.Size = UDim2.new(0, 75, 0, 75) -- 25% larger than the original size
        button.Position = UDim2.new(0.5, 0, (#gamepassFrame:GetChildren() - 1) * 0.25, 0) -- Space buttons vertically
        button.AnchorPoint = Vector2.new(0.5, 0)
        button.BackgroundTransparency = 1
        button.Image = gamepass.Image
        button.Parent = gamepassFrame

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(1, 0) -- Fully circular
        uiCorner.Parent = button

        -- TextLabel for description
        local descriptionLabel = Instance.new("TextLabel")
        descriptionLabel.Size = UDim2.new(0, 100, 0, 30)
        descriptionLabel.Position = UDim2.new(0.5, 0, -0.3, 0) -- Hovering above the button
        descriptionLabel.AnchorPoint = Vector2.new(0.5, 1)
        descriptionLabel.BackgroundColor3 = Color3.new(0, 0, 0)
        descriptionLabel.BackgroundTransparency = 0.5
        descriptionLabel.TextColor3 = Color3.new(1, 1, 1)
        descriptionLabel.TextScaled = true
        descriptionLabel.Text = gamepass.Description
        descriptionLabel.Visible = false
        descriptionLabel.Parent = button

        -- On hover, show the description and add shine effect
        button.MouseEnter:Connect(function()
            descriptionLabel.Visible = true
            -- Shining effect
            for i = 1, 5 do
                button.ImageTransparency = i % 2 == 0 and 0.2 or 0.4
                wait(0.1)
            end
            button.ImageTransparency = 0
        end)

        -- On leave, hide the description and reset shine
        button.MouseLeave:Connect(function()
            descriptionLabel.Visible = false
            button.ImageTransparency = 0
        end)

        -- On click, prompt purchase
        button.MouseButton1Click:Connect(function()
            MarketplaceService:PromptGamePassPurchase(player, gamepass.Id)
        end)
    end

    -- Create buttons for each gamepass
    for _, gamepass in ipairs(gamepasses) do
        createGamepassButton(gamepass)
    end
end

-- Create the GUI initially
createGamepassGui()

-- Recreate the GUI whenever the player respawns
player.CharacterAdded:Connect(function()
    createGamepassGui()
end)
