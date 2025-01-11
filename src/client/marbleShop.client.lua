local replicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote event to toggle the shop UI
local remoteEvent = replicatedStorage:WaitForChild("OpenMarbleShop")

-- Access RemoteEvents
local basicRollEvent = replicatedStorage:WaitForChild("BasicRollEvent")
local rareRollEvent = replicatedStorage:WaitForChild("RareRollEvent")
local legendaryRollEvent = replicatedStorage:WaitForChild("LegendaryRollEvent")


-- Shop GUI instance
local marbleShopGui

-- Function to create the shop UI
local function createShopUI()
    if marbleShopGui then return end -- Avoid creating it multiple times

    -- Create ScreenGui for the shop UI
    marbleShopGui = Instance.new("ScreenGui")
    marbleShopGui.Name = "MarbleShopGui"
    marbleShopGui.Enabled = false
    marbleShopGui.ResetOnSpawn = false -- Prevent reset on respawn
    marbleShopGui.Parent = playerGui

    -- Create the main frame for the shop
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0.5, 0) -- 50% of screen width and height
    frame.Position = UDim2.new(0.25, 0, 0.25, 0) -- Centered
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = marbleShopGui

    -- Add rounded corners to the frame
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0.1, 0) -- Slightly rounded edges for the frame
    frameCorner.Parent = frame

    -- Function to create a button with rounded edges and clean UI
    local function createButton(name, text, position, size, parent, clickFunction)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Text = text
        button.Size = size
        button.Position = position
        button.BackgroundColor3 = Color3.fromRGB(100, 150, 255) -- Light blue background
        button.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold -- Modern and clean font
        button.Parent = parent

        -- Add rounded corners
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.15, 0) -- Rounded corner radius
        corner.Parent = button

        -- Add hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(120, 170, 255) -- Lighter color on hover
        end)

        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(100, 150, 255) -- Revert to original color
        end)

        -- Connect button click function
        button.MouseButton1Click:Connect(clickFunction)

        return button
    end

    -- Create an "X" button for closing the shop
    createButton("CloseButton", "X", UDim2.new(0.92, 0, 0.02, 0), UDim2.new(0.08, 0, 0.1, 0), frame, function()
        marbleShopGui.Enabled = false
    end)

        -- Create buttons for the shop
    createButton("BasicRollButton", "Basic Marble Roll", UDim2.new(0.1, 0, 0.2, 0), UDim2.new(0.8, 0, 0.15, 0), frame, function()
        print("Requesting Basic Marble Roll")
        basicRollEvent:FireServer()
    end)

    createButton("RareRollButton", "Rare Marble Roll", UDim2.new(0.1, 0, 0.4, 0), UDim2.new(0.8, 0, 0.15, 0), frame, function()
        print("Requesting Rare Marble Roll")
        rareRollEvent:FireServer()
    end)

    createButton("LegendaryRollButton", "Legendary Marble Roll", UDim2.new(0.1, 0, 0.6, 0), UDim2.new(0.8, 0, 0.15, 0), frame, function()
        print("Requesting Legendary Marble Roll")
        legendaryRollEvent:FireServer()
    end)

end

-- Function to create the shop button GUI
local function createShopButton()
    -- Check if the shop button already exists
    if playerGui:FindFirstChild("ShopButtonGui") then return end

    -- Create a main UI ScreenGui for the shop button
    local shopButtonGui = Instance.new("ScreenGui")
    shopButtonGui.Name = "ShopButtonGui"
    shopButtonGui.ResetOnSpawn = false -- Prevent reset on respawn
    shopButtonGui.Parent = playerGui

    -- Create a shop button to toggle the shop UI
    local shopButton = Instance.new("TextButton")
    shopButton.Name = "ShopButton"
    shopButton.Text = "Shop"
    shopButton.Size = UDim2.new(0, 150, 0, 50) -- Size of the button
    shopButton.Position = UDim2.new(1, -160, 1, -120) -- Bottom-right corner
    shopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255) -- Light blue background
    shopButton.TextColor3 = Color3.new(1, 1, 1) -- White text
    shopButton.TextScaled = true
    shopButton.Font = Enum.Font.GothamBold -- Clean and modern font
    shopButton.Parent = shopButtonGui

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.15, 0) -- Rounded corner radius
    corner.Parent = shopButton

    -- Add hover effect
    shopButton.MouseEnter:Connect(function()
        shopButton.BackgroundColor3 = Color3.fromRGB(70, 170, 255) -- Slightly lighter on hover
    end)

    shopButton.MouseLeave:Connect(function()
        shopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255) -- Revert to original color
    end)

    -- Toggle the shop UI when the shop button is clicked
    shopButton.MouseButton1Click:Connect(function()
        if not marbleShopGui then
            createShopUI()
        end
        marbleShopGui.Enabled = not marbleShopGui.Enabled
    end)
end

-- Listen for results from the server
basicRollEvent.OnClientEvent:Connect(function(result)
    print("You rolled: " .. result.Name)
end)

rareRollEvent.OnClientEvent:Connect(function(result)
    print("You rolled: " .. result.Name)
end)

legendaryRollEvent.OnClientEvent:Connect(function(result)
    print("You rolled: " .. result.Name)
end)

-- Initialize the shop button and UI
createShopButton()
createShopUI()

-- Ensure shop button persists after player respawns
player.CharacterAdded:Connect(function()
    createShopButton() -- Recreate the button if necessary
end)

-- Toggle the shop UI when the remote event is fired
remoteEvent.OnClientEvent:Connect(function()
    if not marbleShopGui then
        createShopUI()
    end
    marbleShopGui.Enabled = not marbleShopGui.Enabled -- Toggle the GUI visibility
end)
