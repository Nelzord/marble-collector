local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

-- Load Marbles Data
local Marbles = require(ReplicatedStorage.Shared.Marbles)

-- Index Marbles Data by Name for Quick Lookup
local MarbleLookup = {}
for _, marble in ipairs(Marbles) do
    MarbleLookup[marble.Name] = marble
end

-- Fetch Inventory RemoteFunction
local fetchInventoryFunction = ReplicatedStorage:WaitForChild("FetchInventoryFunction")
local marbleColorChangeEvent = ReplicatedStorage:WaitForChild("MarbleColorChangeEvent")

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainUI"
screenGui.Parent = PlayerGui

-- Helper function to create buttons
local function createButton(name, text, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = UDim2.new(0, 150, 0, 50)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.Active = true
    button.Parent = screenGui
    return button
end

-- Define button positions
local screenWidthOffset = -160
local buttonSpacing = 60

-- Create buttons
local inventoryButton = createButton(
    "InventoryButton",
    "Inventory",
    UDim2.new(1, screenWidthOffset, 1, -buttonSpacing * 3)
)

local shopButton = createButton(
    "ShopButton",
    "Shop",
    UDim2.new(1, screenWidthOffset, 1, -buttonSpacing * 2)
)

local levelSelectButton = createButton(
    "LevelSelectButton",
    "Level Selector",
    UDim2.new(1, screenWidthOffset, 1, -buttonSpacing)
)

-- Inventory UI setup
local inventoryFrame = Instance.new("Frame")
inventoryFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
inventoryFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
inventoryFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
inventoryFrame.BorderSizePixel = 0
inventoryFrame.Visible = false
inventoryFrame.Parent = screenGui

-- Add a scrolling frame
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.ScrollBarThickness = 10
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.Parent = inventoryFrame

-- Add close button to inventory
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.05, 0, 0.05, 0)
closeButton.Position = UDim2.new(0.95, -10, 0, 10)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Active = true
closeButton.Parent = inventoryFrame

closeButton.MouseButton1Click:Connect(function()
    inventoryFrame.Visible = false
end)

-- Tooltip for marble description
local tooltip = Instance.new("TextLabel")
tooltip.Size = UDim2.new(0.3, 0, 0.05, 0)
tooltip.Position = UDim2.new(0.35, 0, 0.9, 0)
tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
tooltip.TextColor3 = Color3.new(1, 1, 1)
tooltip.TextScaled = true
tooltip.Font = Enum.Font.SourceSansBold
tooltip.Visible = false
tooltip.Parent = screenGui

-- Function to create rotating marble
local function createRotatingMarble(color)
    local marblePart = Instance.new("Part")
    marblePart.Shape = Enum.PartType.Ball
    marblePart.Size = Vector3.new(7, 7, 7) -- Larger marble
    marblePart.Color = color
    marblePart.Anchored = true

    local function rotate()
        marblePart.CFrame = marblePart.CFrame * CFrame.Angles(0, math.rad(1), 0)
    end

    RunService.RenderStepped:Connect(function()
        if marblePart.Parent then
            rotate()
        end
    end)

    return marblePart
end

-- Function to populate inventory
local function populateInventory()
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
    local xOffset = 10
    local yOffset = 10
    local rowCount = 0
    local marbleFrameSize = 150 -- Frame size for each marble + name

    -- Populate all marbles in Marbles.lua
    for _, marbleData in ipairs(Marbles) do
        local isUnlocked = table.find(unlockedMarbles, marbleData.Name) ~= nil

        local marbleFrame = Instance.new("Frame")
        marbleFrame.Size = UDim2.new(0, marbleFrameSize, 0, marbleFrameSize)
        marbleFrame.Position = UDim2.new(0, xOffset, 0, yOffset)
        marbleFrame.BackgroundTransparency = 1
        marbleFrame.Parent = scrollingFrame

        local viewportFrame = Instance.new("ViewportFrame")
        viewportFrame.Size = UDim2.new(1, 0, 0.7, 0) -- Top part of frame for marble
        viewportFrame.BackgroundTransparency = 1
        viewportFrame.Parent = marbleFrame

        local marblePart = createRotatingMarble(marbleData.Color)
        local viewportCamera = Instance.new("Camera")
        viewportCamera.CFrame = CFrame.new(Vector3.new(0, 0, 15), Vector3.new(0, 0, 0))
        viewportFrame.CurrentCamera = viewportCamera
        marblePart.Parent = viewportFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.Position = UDim2.new(0, 0, 0.7, 0)
        nameLabel.Text = marbleData.Name
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.Parent = marbleFrame

        if not isUnlocked then
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
        else
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

-- Inventory Button Functionality
inventoryButton.MouseButton1Click:Connect(function()
    inventoryFrame.Visible = not inventoryFrame.Visible
    if inventoryFrame.Visible then
        populateInventory()
    end
end)

-- Shop Button Functionality
shopButton.MouseButton1Click:Connect(function()
    print("Shop button clicked! Add your shop functionality here.")
end)

-- Level Selector Button Functionality
levelSelectButton.MouseButton1Click:Connect(function()
    print("Level Selector button clicked! Add your level selection functionality here.")
end)
