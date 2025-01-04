local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainUI"
screenGui.Parent = PlayerGui

-- Helper function to create buttons
local function createButton(name, text, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = UDim2.new(0, 150, 0, 50) -- Button size (width, height)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 200) -- Blue color
    button.TextColor3 = Color3.new(1, 1, 1) -- White text
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.Active = true -- Ensure the button is active
    button.Parent = screenGui
    return button
end

-- Define button positions (bottom-right corner)
local screenWidthOffset = -160 -- Horizontal offset
local buttonSpacing = 60 -- Vertical spacing

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


local inventoryFrame = Instance.new("Frame")
inventoryFrame.Size = UDim2.new(0.4, 0, 0.6, 0) -- 40% width, 60% height
inventoryFrame.Position = UDim2.new(0.3, 0, 0.2, 0) -- Centered on the screen
inventoryFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
inventoryFrame.BorderSizePixel = 0
inventoryFrame.Visible = false -- Initially hidden
inventoryFrame.Parent = screenGui

-- Add a scrolling frame
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will adjust dynamically
scrollingFrame.ScrollBarThickness = 10
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.Parent = inventoryFrame

-- Add close button to inventory
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.1, 0, 0.1, 0)
closeButton.Position = UDim2.new(0.9, -10, 0, 10)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Active = true -- Ensure the button is active
closeButton.Parent = inventoryFrame

closeButton.MouseButton1Click:Connect(function()
    inventoryFrame.Visible = false
end)

-- Inventory Button Functionality
inventoryButton.MouseButton1Click:Connect(function()
    inventoryFrame.Visible = not inventoryFrame.Visible
end)


local Marbles = require(game.ReplicatedStorage.Shared.Marbles)
-- Function to populate inventory
local marbleColorChangeEvent = ReplicatedStorage:WaitForChild("MarbleColorChangeEvent")

-- Function to populate inventory
local function populateInventory()
    local yOffset = 10
    for _, marble in ipairs(Marbles) do
        local marbleButton = Instance.new("TextButton")
        marbleButton.Size = UDim2.new(0.8, 0, 0, 50)
        marbleButton.Position = UDim2.new(0.1, 0, 0, yOffset)
        marbleButton.Text = marble.Name
        marbleButton.BackgroundColor3 = marble.Color
        marbleButton.TextColor3 = Color3.new(1, 1, 1)
        marbleButton.TextScaled = true
        marbleButton.Font = Enum.Font.SourceSans
        marbleButton.Parent = scrollingFrame

        -- Handle marble selection
        marbleButton.MouseButton1Click:Connect(function()
            print("Selected marble:", marble.Name)
            marbleColorChangeEvent:FireServer(marble.Color) -- Send color to the server
        end)

        yOffset = yOffset + 60 -- Adjust for spacing
    end

    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset) -- Update scrolling size
end

populateInventory()
