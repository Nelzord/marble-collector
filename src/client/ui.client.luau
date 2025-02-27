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
local teleportToLevelEvent = ReplicatedStorage:WaitForChild("TeleportToLevelEvent")
local openMarbleShop = ReplicatedStorage:WaitForChild("OpenMarbleShop")
local marbleTextureChangeEvent = ReplicatedStorage:WaitForChild("MarbleTextureChangeEvent")


local function createRotatingMarble(viewportFrame, color, textureId)
    -- Create the marble part
    local marblePart = Instance.new("Part")
    marblePart.Shape = Enum.PartType.Ball
    marblePart.Size = Vector3.new(7, 7, 7)
    marblePart.Anchored = true
    marblePart.Parent = viewportFrame

    -- Apply texture using Decal
    if textureId then
        for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
            local decal = Instance.new("Decal")
            decal.Texture = textureId
            decal.Face = face
            decal.Parent = marblePart
        end
        print("Applied texture to marble:", textureId)
    else
        -- Fallback to color if no texture provided
        marblePart.Color = color
        print("No textureId provided. Using color:", color)
    end

    -- Create and set up the camera for the viewport frame
    local viewportCamera = Instance.new("Camera")
    viewportCamera.CFrame = CFrame.new(Vector3.new(0, 0, 15), Vector3.new(0, 0, 0))
    viewportFrame.CurrentCamera = viewportCamera

    -- Add rotation animation for the marble
    local rotationConnection
    rotationConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if marblePart.Parent then
            marblePart.CFrame = marblePart.CFrame * CFrame.Angles(0, math.rad(1), 0)
        else
            rotationConnection:Disconnect() -- Disconnect if the marble is removed
        end
    end)
end

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
    local marbleFrameSize = (scrollingFrame.AbsoluteSize.X - 50) / 4 -- Dynamically adjust size
    local columns = math.floor(scrollingFrame.AbsoluteSize.X / marbleFrameSize) -- Calculate columns

    for _, marbleData in ipairs(Marbles) do
        local isUnlocked = table.find(unlockedMarbles, marbleData.Name) ~= nil

        -- Create marble frame
        local marbleFrame = Instance.new("Frame")
        marbleFrame.Size = UDim2.new(0, marbleFrameSize, 0, marbleFrameSize)
        marbleFrame.Position = UDim2.new(0, xOffset, 0, yOffset)
        marbleFrame.BackgroundTransparency = 0.2
        marbleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Neutral gray
        marbleFrame.Parent = scrollingFrame

        -- Add rounded corners to marble frame
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0.1, 0)
        frameCorner.Parent = marbleFrame

        -- Create viewport frame for rotating marble
        local viewportFrame = Instance.new("ViewportFrame")
        viewportFrame.Size = UDim2.new(1, 0, 0.7, 0)
        viewportFrame.BackgroundTransparency = 1
        viewportFrame.Parent = marbleFrame

        createRotatingMarble(viewportFrame, marbleData.Color, marbleData.TextureId)

        -- Create name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.Position = UDim2.new(0, 0, 0.7, 0)
        nameLabel.Text = marbleData.Name
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold -- Clean font
        nameLabel.Parent = marbleFrame

        if isUnlocked then
            -- Create a clickable button over the marble
            local clickButton = Instance.new("TextButton")
            clickButton.Size = UDim2.new(1, 0, 1, 0)
            clickButton.BackgroundTransparency = 1
            clickButton.Parent = marbleFrame

            -- Tooltip for unlocked marble
            clickButton.MouseEnter:Connect(function()
                tooltip.Text = marbleData.Description
                tooltip.Visible = true
            end)
            clickButton.MouseLeave:Connect(function()
                tooltip.Visible = false
            end)
            clickButton.MouseButton1Click:Connect(function()
                if marbleData.TextureId then
                    marbleTextureChangeEvent:FireServer(marbleData.TextureId) -- Send only the TextureId
                    print("Selected marble:", marbleData.Name)
                else
                    warn("No TextureId for selected marble:", marbleData.Name)
                end
                print("Selected marble:", marbleData.Name)
            end)
        else
            -- Locked banner for locked marbles
            local lockedBanner = Instance.new("TextLabel")
            lockedBanner.Size = UDim2.new(1, 0, 0.3, 0)
            lockedBanner.Position = UDim2.new(0, 0, 0.35, 0)
            lockedBanner.Text = "LOCKED"
            lockedBanner.BackgroundTransparency = 0.2
            lockedBanner.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black background
            lockedBanner.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red text
            lockedBanner.TextScaled = true
            lockedBanner.Font = Enum.Font.GothamBold
            lockedBanner.Parent = marbleFrame

            -- Add rounded corners to locked banner
            local bannerCorner = Instance.new("UICorner")
            bannerCorner.CornerRadius = UDim.new(0.1, 0)
            bannerCorner.Parent = lockedBanner
        end

        -- Adjust position for the next marble
        xOffset = xOffset + marbleFrameSize + 10
        if xOffset + marbleFrameSize > scrollingFrame.AbsoluteSize.X then
            xOffset = 10
            yOffset = yOffset + marbleFrameSize + 10
        end
    end

    -- Update the canvas size of the scrolling frame to fit all items
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + marbleFrameSize + 10)
end

local function populateLevelSelector(levelScrollingFrame)
    -- Clear existing children
    levelScrollingFrame:ClearAllChildren()

    -- Fetch inventory data from the server
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

        -- Create the frame for the level
        local levelFrame = Instance.new("Frame")
        levelFrame.Size = UDim2.new(0.9, 0, 0, buttonHeight)
        levelFrame.Position = UDim2.new(0.05, 0, 0, yOffset)
        levelFrame.BackgroundColor3 = isCompleted and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50) -- Green for completed, red for locked
        levelFrame.BorderSizePixel = 0
        levelFrame.Parent = levelScrollingFrame

        -- Add rounded corners to the frame
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0.15, 0)
        frameCorner.Parent = levelFrame

        -- Add the name label
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, -10, 1, 0) -- Leave space for buttons
        nameLabel.Position = UDim2.new(0, 10, 0, 0) -- Slightly offset from the left
        nameLabel.Text = levelData.Name
        nameLabel.TextScaled = true
        nameLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
        nameLabel.Font = Enum.Font.GothamBold -- Clean font
        nameLabel.BackgroundTransparency = 1
        nameLabel.Parent = levelFrame

        -- Add interaction button (Replay or Locked)
        if isCompleted then
            local replayButton = Instance.new("TextButton")
            replayButton.Size = UDim2.new(0.25, 0, 0.8, 0) -- Adjust size for cleaner alignment
            replayButton.Position = UDim2.new(0.75, 0, 0.1, 0) -- Slightly inset
            replayButton.Text = "Replay"
            replayButton.TextScaled = true
            replayButton.BackgroundColor3 = Color3.fromRGB(50, 50, 200) -- Blue button
            replayButton.TextColor3 = Color3.new(1, 1, 1) -- White text
            replayButton.Font = Enum.Font.GothamBold
            replayButton.Parent = levelFrame

            -- Add rounded corners to the button
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0.15, 0)
            buttonCorner.Parent = replayButton

            -- Connect the button to replay the level
            replayButton.MouseButton1Click:Connect(function()
                print("Loading level:", levelData.Name)
                teleportToLevelEvent:FireServer(levelData.Location)
            end)
        else
            local lockedLabel = Instance.new("TextLabel")
            lockedLabel.Size = UDim2.new(0.25, 0, 0.8, 0) -- Adjust size for cleaner alignment
            lockedLabel.Position = UDim2.new(0.75, 0, 0.1, 0) -- Slightly inset
            lockedLabel.Text = "LOCKED"
            lockedLabel.TextScaled = true
            lockedLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red text
            lockedLabel.Font = Enum.Font.GothamBold
            lockedLabel.BackgroundTransparency = 1
            lockedLabel.Parent = levelFrame
        end

        -- Update yOffset for the next level
        yOffset = yOffset + buttonHeight + 10
    end

    -- Update scrolling frame canvas size to fit all levels
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

    -- Function to create a button with rounded edges and clean UI
local function createButton(name, text, position, parent, clickFunction)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = UDim2.new(0, 150, 0, 50) -- Button size
    button.Position = position -- Button position
    button.BackgroundColor3 = Color3.fromRGB(50, 150, 250) -- Light blue background
    button.TextColor3 = Color3.new(1, 1, 1) -- White text
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold -- Clean font
    button.Parent = parent

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.2, 0) -- Rounded corner radius (adjust as needed)
    corner.Parent = button

    -- Add hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(70, 170, 255) -- Slightly lighter on hover
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(50, 150, 250) -- Revert to original color
    end)

    -- Connect button click function
    button.MouseButton1Click:Connect(clickFunction)

    return button
end

    local screenWidthOffset = -160
    local buttonSpacing = 60

    createButton("InventoryButton", "Inventory", UDim2.new(1, screenWidthOffset, 1, -buttonSpacing * 3), screenGui, function()
        inventoryFrame.Visible = not inventoryFrame.Visible
        if inventoryFrame.Visible then
            populateInventory(scrollingFrame, tooltip)
        end
    end)

    

    createButton("LevelSelectButton", "Level Selector", UDim2.new(1, screenWidthOffset, 1, -buttonSpacing), screenGui, function()
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

