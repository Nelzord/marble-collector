local replicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remote event to toggle the shop UI
local remoteEvent = replicatedStorage:WaitForChild("OpenMarbleShop")

-- Access RemoteEvents
local basicRollEvent = replicatedStorage:WaitForChild("BasicRollEvent")
local rareRollEvent = replicatedStorage:WaitForChild("RareRollEvent")
local legendaryRollEvent = replicatedStorage:WaitForChild("LegendaryRollEvent")
local unlockMarbleEvent = replicatedStorage:WaitForChild("UnlockMarbleEvent")

-- Shop GUI instance
local marbleShopGui
local inspectGui

-- Require shared marble data
local marbleData = require(replicatedStorage.Shared.Marbles)


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

-- Function to create the inspect UI with marbles showcase
local function createInspectUI(rarityFilter)
    if inspectGui then
        inspectGui:Destroy()
    end

    inspectGui = Instance.new("ScreenGui")
    inspectGui.Name = "InspectGui"
    inspectGui.Enabled = true
    inspectGui.ResetOnSpawn = false
    inspectGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.7, 0, 0.8, 0)
    frame.Position = UDim2.new(0.15, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = inspectGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0.1, 0)
    frameCorner.Parent = frame

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Text = "Close"
    closeButton.Size = UDim2.new(0.2, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.4, 0, 0.85, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.15, 0)
    corner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        inspectGui.Enabled = false
    end)

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
    scrollFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 10
    scrollFrame.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0.05, 0)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame

    for _, marble in ipairs(marbleData) do
        if not rarityFilter or marble.Rarity == rarityFilter then
            local viewportFrame = Instance.new("ViewportFrame")
            viewportFrame.Size = UDim2.new(1, 0, 0.3, 0)
            viewportFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            viewportFrame.BorderSizePixel = 0
            viewportFrame.Parent = scrollFrame

            local viewportCorner = Instance.new("UICorner")
            viewportCorner.CornerRadius = UDim.new(0.1, 0)
            viewportCorner.Parent = viewportFrame

            local marbleName = Instance.new("TextLabel")
            marbleName.Text = marble.Name .. " - " .. marble.Rarity
            marbleName.Size = UDim2.new(1, 0, 0.2, 0)
            marbleName.Position = UDim2.new(0, 0, 0, 0)
            marbleName.BackgroundTransparency = 1
            marbleName.TextColor3 = Color3.fromRGB(255, 255, 255)
            marbleName.TextScaled = true
            marbleName.Font = Enum.Font.GothamBold
            marbleName.Parent = viewportFrame

            local marbleDescription = Instance.new("TextLabel")
            marbleDescription.Text = marble.Description
            marbleDescription.Size = UDim2.new(1, 0, 0.2, 0)
            marbleDescription.Position = UDim2.new(0, 0, 0.2, 0)
            marbleDescription.BackgroundTransparency = 1
            marbleDescription.TextColor3 = Color3.fromRGB(200, 200, 200)
            marbleDescription.TextScaled = true
            marbleDescription.Font = Enum.Font.Gotham
            marbleDescription.TextWrapped = true
            marbleDescription.Parent = viewportFrame

            createRotatingMarble(viewportFrame, marble.Color, marble.TextureId)
        end
    end
end

-- Function to create the shop UI
local function createShopUI()
    if marbleShopGui then return end

    marbleShopGui = Instance.new("ScreenGui")
    marbleShopGui.Name = "MarbleShopGui"
    marbleShopGui.Enabled = false
    marbleShopGui.ResetOnSpawn = false
    marbleShopGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.7, 0, 0.8, 0)
    frame.Position = UDim2.new(0.15, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = marbleShopGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0.1, 0)
    frameCorner.Parent = frame

    local function createButton(name, text, position, size, parent, clickFunction)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Text = text
        button.Size = size
        button.Position = position
        button.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.15, 0)
        corner.Parent = button

        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(120, 170, 255)
        end)

        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        end)

        button.MouseButton1Click:Connect(clickFunction)

        return button
    end

    local function createRollSection(name, rollText, inspectText, buyText, rollEvent, position, rarityFilter)
        local rollLabel = Instance.new("TextLabel")
        rollLabel.Text = rollText
        rollLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
        rollLabel.Position = position
        rollLabel.BackgroundTransparency = 1
        rollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        rollLabel.TextScaled = true
        rollLabel.Font = Enum.Font.GothamBold
        rollLabel.TextWrapped = true
        rollLabel.Parent = frame

        local inspectButton = createButton(name .. "InspectButton", inspectText, position + UDim2.new(0, 0, 0.15, 0), UDim2.new(0.8, 0, 0.08, 0), frame, function()
            createInspectUI(rarityFilter)
        end)

        local buyButton = createButton(name .. "BuyButton", buyText, position + UDim2.new(0, 0, 0.25, 0), UDim2.new(0.8, 0, 0.08, 0), frame, function()
            print("Requesting " .. rollText)
            rollEvent:FireServer()
        end)
    end

createRollSection("Basic", "Basic Marble Roll (50 Coins)", "Inspect Basic Marbles", "Buy Basic Marble Roll", basicRollEvent, UDim2.new(0.1, 0, 0, 0), "Common")
createRollSection("Rare", "Rare Marble Roll (150 Coins)", "Inspect Rare Marbles", "Buy Rare Marble Roll", rareRollEvent, UDim2.new(0.1, 0, 0.35, 0), "Rare")
createRollSection("Legendary", "Legendary Marble Roll (500 Coins)", "Inspect Legendary Marbles", "Buy Legendary Marble Roll", legendaryRollEvent, UDim2.new(0.1, 0, 0.7, 0), "Legendary")

    createButton("CloseButton", "X", UDim2.new(0.92, 0, 0.02, 0), UDim2.new(0.08, 0, 0.08, 0), frame, function()
        marbleShopGui.Enabled = false
    end)
end

local function createShopButton()
    if playerGui:FindFirstChild("ShopButtonGui") then return end

    local shopButtonGui = Instance.new("ScreenGui")
    shopButtonGui.Name = "ShopButtonGui"
    shopButtonGui.ResetOnSpawn = false
    shopButtonGui.Parent = playerGui

    local shopButton = Instance.new("TextButton")
    shopButton.Name = "ShopButton"
    shopButton.Text = "Shop"
    shopButton.Size = UDim2.new(0, 150, 0, 50)
    shopButton.Position = UDim2.new(1, -160, 1, -120)
    shopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    shopButton.TextColor3 = Color3.new(1, 1, 1)
    shopButton.TextScaled = true
    shopButton.Font = Enum.Font.GothamBold
    shopButton.Parent = shopButtonGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.15, 0)
    corner.Parent = shopButton

    shopButton.MouseEnter:Connect(function()
        shopButton.BackgroundColor3 = Color3.fromRGB(70, 170, 255)
    end)

    shopButton.MouseLeave:Connect(function()
        shopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    end)

    shopButton.MouseButton1Click:Connect(function()
        if not marbleShopGui then
            createShopUI()
        end
        marbleShopGui.Enabled = not marbleShopGui.Enabled
    end)
end

basicRollEvent.OnClientEvent:Connect(function(result)
    print("You rolled: " .. result.Name)
    unlockMarbleEvent:FireServer(result.Name)
end)

rareRollEvent.OnClientEvent:Connect(function(result)
    print("You rolled: " .. result.Name)
    unlockMarbleEvent:FireServer(result.Name)
end)

legendaryRollEvent.OnClientEvent:Connect(function(result)
    print("You rolled: " .. result.Name)
    unlockMarbleEvent:FireServer(result.Name)
end)

createShopButton()
createShopUI()

player.CharacterAdded:Connect(function()
    createShopButton()
end)

remoteEvent.OnClientEvent:Connect(function()
    if not marbleShopGui then
        createShopUI()
    end
    marbleShopGui.Enabled = not marbleShopGui.Enabled
end)
