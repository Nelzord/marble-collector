local replicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Use an existing RemoteEvent for Mythic Rolls
local mythicRollEvent = replicatedStorage:WaitForChild("LegendaryRollEvent") -- Reusing LegendaryRollEvent
local unlockMarbleEvent = replicatedStorage:WaitForChild("UnlockMarbleEvent")
local remoteEvent = replicatedStorage:WaitForChild("OpenMarbleShop")

-- Require shared marble data
local marbleData = require(replicatedStorage.Shared.Marbles)

-- Function to create a rotating marble preview
local function createRotatingMarble(viewportFrame, color, textureId)
    local marblePart = Instance.new("Part")
    marblePart.Shape = Enum.PartType.Ball
    marblePart.Size = Vector3.new(7, 7, 7)
    marblePart.Anchored = true
    marblePart.Parent = viewportFrame

    if textureId then
        for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
            local decal = Instance.new("Decal")
            decal.Texture = textureId
            decal.Face = face
            decal.Parent = marblePart
        end
    else
        marblePart.Color = color
    end

    local viewportCamera = Instance.new("Camera")
    viewportCamera.CFrame = CFrame.new(Vector3.new(0, 0, 15), Vector3.new(0, 0, 0))
    viewportFrame.CurrentCamera = viewportCamera

    local rotationConnection
    rotationConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if marblePart.Parent then
            marblePart.CFrame = marblePart.CFrame * CFrame.Angles(0, math.rad(1), 0)
        else
            rotationConnection:Disconnect()
        end
    end)
end

-- Function to create a notification for the marble won
local function createNotification(marble)
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.4, 0, 0.2, 0)
    frame.Position = UDim2.new(0.3, 0, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Parent = notificationGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0.1, 0)
    frameCorner.Parent = frame

    local marbleName = Instance.new("TextLabel")
    marbleName.Text = "You won: " .. marble.Name
    marbleName.Size = UDim2.new(1, 0, 0.4, 0)
    marbleName.Position = UDim2.new(0, 0, 0, 0)
    marbleName.BackgroundTransparency = 1
    marbleName.TextColor3 = Color3.fromRGB(255, 255, 255)
    marbleName.TextScaled = true
    marbleName.Font = Enum.Font.GothamBold
    marbleName.Parent = frame

    local viewportFrame = Instance.new("ViewportFrame")
    viewportFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
    viewportFrame.Position = UDim2.new(0.2, 0, 0.4, 0)
    viewportFrame.BackgroundTransparency = 1
    viewportFrame.Parent = frame

    createRotatingMarble(viewportFrame, marble.Color, marble.TextureId)

    task.delay(3, function()
        notificationGui:Destroy()
    end)
end

-- Function to create the inspect UI
local function createInspectUI()
    if inspectGui then
        inspectGui:Destroy()
    end

    inspectGui = Instance.new("ScreenGui")
    inspectGui.Name = "InspectGui"
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
    closeButton.Text = "Close"
    closeButton.Size = UDim2.new(0.2, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.4, 0, 0.85, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = frame

    closeButton.MouseButton1Click:Connect(function()
        inspectGui:Destroy()
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
        marbleName.BackgroundTransparency = 1
        marbleName.TextColor3 = Color3.fromRGB(255, 255, 255)
        marbleName.TextScaled = true
        marbleName.Font = Enum.Font.GothamBold
        marbleName.Parent = viewportFrame

        createRotatingMarble(viewportFrame, marble.Color, marble.TextureId)
    end
end

-- Function to create the shop UI
local function createShopUI()
    if marbleShopGui then return end

    marbleShopGui = Instance.new("ScreenGui")
    marbleShopGui.Name = "MarbleShopGui"
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

    local closeButton = Instance.new("TextButton")
    closeButton.Text = "X"
    closeButton.Size = UDim2.new(0.08, 0, 0.08, 0)
    closeButton.Position = UDim2.new(0.92, 0, 0.02, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = frame

    closeButton.MouseButton1Click:Connect(function()
        marbleShopGui.Enabled = false
    end)

    local rollLabel = Instance.new("TextLabel")
    rollLabel.Text = "Mythic Marble Roll (Limited Time)"
    rollLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
    rollLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
    rollLabel.BackgroundTransparency = 1
    rollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rollLabel.TextScaled = true
    rollLabel.Font = Enum.Font.GothamBold
    rollLabel.Parent = frame

    local inspectButton = Instance.new("TextButton")
    inspectButton.Text = "Inspect Marbles"
    inspectButton.Size = UDim2.new(0.8, 0, 0.1, 0)
    inspectButton.Position = UDim2.new(0.1, 0, 0.25, 0)
    inspectButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    inspectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    inspectButton.TextScaled = true
    inspectButton.Font = Enum.Font.GothamBold
    inspectButton.Parent = frame

    inspectButton.MouseButton1Click:Connect(function()
        createInspectUI()
    end)

    local buyButton = Instance.new("TextButton")
    buyButton.Text = "Buy Mythic Marble Roll"
    buyButton.Size = UDim2.new(0.8, 0, 0.1, 0)
    buyButton.Position = UDim2.new(0.1, 0, 0.4, 0)
    buyButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyButton.TextScaled = true
    buyButton.Font = Enum.Font.GothamBold
    buyButton.Parent = frame

    buyButton.MouseButton1Click:Connect(function()
        mythicRollEvent:FireServer()
    end)
end

-- Handle the roll result
mythicRollEvent.OnClientEvent:Connect(function(result)
    createNotification(result)
    unlockMarbleEvent:FireServer(result.Name)
end)

-- Function to create the shop button
local function createShopButton()
    local shopButtonGui = Instance.new("ScreenGui")
    shopButtonGui.Name = "ShopButtonGui"
    shopButtonGui.Parent = playerGui

    local shopButton = Instance.new("TextButton")
    shopButton.Text = "Shop"
    shopButton.Size = UDim2.new(0, 150, 0, 50)
    shopButton.Position = UDim2.new(1, -160, 1, -120)
    shopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    shopButton.TextScaled = true
    shopButton.Font = Enum.Font.GothamBold
    shopButton.Parent = shopButtonGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.15, 0)
    corner.Parent = shopButton

    shopButton.MouseButton1Click:Connect(function()
        if not marbleShopGui then
            createShopUI()
        end
        marbleShopGui.Enabled = not marbleShopGui.Enabled
    end)
end

createShopButton()
