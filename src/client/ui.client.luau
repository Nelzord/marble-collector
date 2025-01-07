local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Load Marbles and Levels Data
local Marbles = require(ReplicatedStorage.Shared.Marbles)
local Levels = require(ReplicatedStorage.Shared.Levels)

-- Fetch Remote Functions and Events
local fetchInventoryFunction = ReplicatedStorage:WaitForChild("FetchInventoryFunction")
local marbleColorChangeEvent = ReplicatedStorage:WaitForChild("MarbleColorChangeEvent")
local teleportToLevelEvent = ReplicatedStorage:WaitForChild("TeleportToLevelEvent")

-- Function to create a rotating marble
local function createRotatingMarble(viewportFrame, color)
    local marblePart = Instance.new("Part")
    marblePart.Shape = Enum.PartType.Ball
    marblePart.Size = Vector3.new(7, 7, 7)
    marblePart.Color = color
    marblePart.Anchored = true
    marblePart.Parent = viewportFrame

    local viewportCamera = Instance.new("Camera")
    viewportCamera.CFrame = CFrame.new(Vector3.new(0, 0, 15), Vector3.new(0, 0, 0))
    viewportFrame.CurrentCamera = viewportCamera

    RunService.RenderStepped:Connect(function()
        if marblePart.Parent then
            marblePart.CFrame = marblePart.CFrame * CFrame.Angles(0, math.rad(1), 0)
        end
    end)
end

-- Function to populate the inventory UI
local function populateInventory(scrollingFrame, tooltip)
    scrollingFrame:ClearAllChildren()
    tooltip.Visible = false

    local success, inventory = pcall(function()
        return fetchInventoryFunction:InvokeServer()
    end)

    if not success then
        warn("Failed to fetch inventory from server")
        return
    end

    local unlockedMarbles = inventory.unlockedMarbles or {}
    local xOffset, yOffset = 10, 10
    local rowCount = 0
    local marbleFrameSize = 150

    for _, marbleData in ipairs(Marbles) do
        local isUnlocked = table.find(unlockedMarbles, marbleData.Name) ~= nil

        local marbleFrame = Instance.new("Frame")
        marbleFrame.Size = UDim2.new(0, marbleFrameSize, 0, marbleFrameSize)
        marbleFrame.Position = UDim2.new(0, xOffset, 0, yOffset)
        marbleFrame.BackgroundTransparency = 1
        marbleFrame.Parent = scrollingFrame

        local viewportFrame = Instance.new("ViewportFrame")
        viewportFrame.Size = UDim2.new(1, 0, 0.7, 0)
        viewportFrame.BackgroundTransparency = 1
        viewportFrame.Parent = marbleFrame

        createRotatingMarble(viewportFrame, marbleData.Color)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.Position = UDim2.new(0, 0, 0.7, 0)
        nameLabel.Text = marbleData.Name
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.Parent = marbleFrame

        if isUnlocked then
            local clickButton = Instance.new("TextButton")
            clickButton.Size = UDim2.new(1, 0, 1, 0)
            clickButton.BackgroundTransparency = 1
            clickButton.Parent = marbleFrame

            clickButton.MouseEnter:Connect(function()
                tooltip.Text = marbleData.Description
                tooltip.Visible = true
            end)
            clickButton.MouseLeave:Connect(function()
                tooltip.Visible = false
            end)
            clickButton.MouseButton1Click:Connect(function()
                print("Selected marble:", marbleData.Name)
                marbleColorChangeEvent:FireServer(marbleData.Color)
            end)
        else
            local lockedBanner = Instance.new("TextLabel")
            lockedBanner.Size = UDim2.new(1, 0, 0.3, 0)
            lockedBanner.Position = UDim2.new(0, 0, 0.35, 0)
            lockedBanner.Text = "LOCKED"
            lockedBanner.BackgroundTransparency = 0.5
            lockedBanner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            lockedBanner.TextColor3 = Color3.fromRGB(255, 0, 0)
            lockedBanner.TextScaled = true
            lockedBanner.Font = Enum.Font.SourceSansBold
            lockedBanner.Parent = marbleFrame
        end

        xOffset = xOffset + marbleFrameSize + 10
        rowCount = rowCount + 1
        if rowCount == 4 then
            rowCount = 0
            xOffset = 10
            yOffset = yOffset + marbleFrameSize + 10
        end
    end

    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + marbleFrameSize + 10)
end

local function populateLevelSelector(levelScrollingFrame)
    levelScrollingFrame:ClearAllChildren()

    local success, inventory = pcall(function()
        return fetchInventoryFunction:InvokeServer()
    end)

    if not success then
        warn("Failed to fetch inventory from server")
        return
    end

    local beatenLevels = inventory.beatenLevels or {}
    local yOffset = 10
    local buttonHeight = 70

    for _, levelData in ipairs(Levels) do
        local isCompleted = table.find(beatenLevels, levelData.Location) ~= nil

        local levelFrame = Instance.new("Frame")
        levelFrame.Size = UDim2.new(0.9, 0, 0, buttonHeight)
        levelFrame.Position = UDim2.new(0.05, 0, 0, yOffset)
        levelFrame.BackgroundColor3 = isCompleted and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        levelFrame.BorderSizePixel = 0
        levelFrame.Parent = levelScrollingFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.Text = levelData.Name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.BackgroundTransparency = 1
        nameLabel.Parent = levelFrame

        if isCompleted then
            local replayButton = Instance.new("TextButton")
            replayButton.Size = UDim2.new(0.2, 0, 1, 0)
            replayButton.Position = UDim2.new(0.8, 0, 0, 0)
            replayButton.Text = "Replay"
            replayButton.TextScaled = true
            replayButton.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
            replayButton.TextColor3 = Color3.new(1, 1, 1)
            replayButton.Font = Enum.Font.SourceSansBold
            replayButton.Parent = levelFrame

            replayButton.MouseButton1Click:Connect(function()
                print("Loading level:", levelData.Name)
                teleportToLevelEvent:FireServer(levelData.Location)
            end)
        else
            local lockedLabel = Instance.new("TextLabel")
            lockedLabel.Size = UDim2.new(0.2, 0, 1, 0)
            lockedLabel.Position = UDim2.new(0.8, 0, 0, 0)
            lockedLabel.Text = "LOCKED"
            lockedLabel.TextScaled = true
            lockedLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            lockedLabel.Font = Enum.Font.SourceSansBold
            lockedLabel.BackgroundTransparency = 1
            lockedLabel.Parent = levelFrame
        end

        yOffset = yOffset + buttonHeight + 10
    end

    levelScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Function to set up the UI
local function setupUI()
    -- Clear existing UI if any
    local existingGui = PlayerGui:FindFirstChild("MainUI")
    if existingGui then
        existingGui:Destroy()
    end

    -- Create the main UI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainUI"
    screenGui.Parent = PlayerGui

    -- Tooltip
    local tooltip = Instance.new("TextLabel")
    tooltip.Size = UDim2.new(0.3, 0, 0.05, 0)
    tooltip.Position = UDim2.new(0.35, 0, 0.9, 0)
    tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tooltip.TextColor3 = Color3.new(1, 1, 1)
    tooltip.TextScaled = true
    tooltip.Font = Enum.Font.SourceSansBold
    tooltip.Visible = false
    tooltip.Parent = screenGui

    -- Inventory UI
    local inventoryFrame = Instance.new("Frame")
    inventoryFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    inventoryFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    inventoryFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    inventoryFrame.BorderSizePixel = 0
    inventoryFrame.Visible = false
    inventoryFrame.Parent = screenGui

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.ScrollBarThickness = 10
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.Parent = inventoryFrame

    -- Close Inventory Button
    local closeInventoryButton = Instance.new("TextButton")
    closeInventoryButton.Size = UDim2.new(0.05, 0, 0.05, 0)
    closeInventoryButton.Position = UDim2.new(0.95, -10, 0, 10)
    closeInventoryButton.Text = "X"
    closeInventoryButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeInventoryButton.TextColor3 = Color3.new(1, 1, 1)
    closeInventoryButton.Font = Enum.Font.SourceSansBold
    closeInventoryButton.Parent = inventoryFrame
    closeInventoryButton.MouseButton1Click:Connect(function()
        inventoryFrame.Visible = false
    end)

    -- Level Selector UI
    local levelSelectFrame = Instance.new("Frame")
    levelSelectFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
    levelSelectFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    levelSelectFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    levelSelectFrame.BorderSizePixel = 0
    levelSelectFrame.Visible = false
    levelSelectFrame.Parent = screenGui

    local levelScrollingFrame = Instance.new("ScrollingFrame")
    levelScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    levelScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    levelScrollingFrame.ScrollBarThickness = 10
    levelScrollingFrame.BackgroundTransparency = 1
    levelScrollingFrame.Parent = levelSelectFrame

    -- Close Level Selector Button
    local closeLevelButton = Instance.new("TextButton")
    closeLevelButton.Size = UDim2.new(0.05, 0, 0.05, 0)
    closeLevelButton.Position = UDim2.new(0.95, -10, 0, 10)
    closeLevelButton.Text = "X"
    closeLevelButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeLevelButton.TextColor3 = Color3.new(1, 1, 1)
    closeLevelButton.Font = Enum.Font.SourceSansBold
    closeLevelButton.Parent = levelSelectFrame
    closeLevelButton.MouseButton1Click:Connect(function()
        levelSelectFrame.Visible = false
    end)

    -- Buttons
    local function createButton(name, text, position, clickFunction)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Text = text
        button.Size = UDim2.new(0, 150, 0, 50)
        button.Position = position
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSansBold
        button.Parent = screenGui
        button.MouseButton1Click:Connect(clickFunction)
        return button
    end

    local screenWidthOffset = -160
    local buttonSpacing = 60

    createButton("InventoryButton", "Inventory", UDim2.new(1, screenWidthOffset, 1, -buttonSpacing * 3), function()
        inventoryFrame.Visible = not inventoryFrame.Visible
        if inventoryFrame.Visible then
            populateInventory(scrollingFrame, tooltip)
        end
    end)

    createButton("ShopButton", "Shop", UDim2.new(1, screenWidthOffset, 1, -buttonSpacing * 2), function()
        print("Shop button clicked! Implement shop functionality here.")
    end)

    createButton("LevelSelectButton", "Level Selector", UDim2.new(1, screenWidthOffset, 1, -buttonSpacing), function()
        levelSelectFrame.Visible = not levelSelectFrame.Visible
        if levelSelectFrame.Visible then
            populateLevelSelector(levelScrollingFrame)
        end
    end)
end

-- Trigger setup on character respawn
player.CharacterAdded:Connect(function()
    setupUI()
end)

-- Initial setup
if player.Character then
    setupUI()
end

