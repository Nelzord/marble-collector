local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Get the RemoteEvent and RemoteFunction for coin updates
local addCoinsEvent = ReplicatedStorage:WaitForChild("AddCoinsEvent")
local fetchInventoryFunction = ReplicatedStorage:WaitForChild("FetchInventoryFunction")

-- Throttle variables
local lastCoinCollectionTime = 0
local coinCollectionCooldown = 0.5 -- 0.5 seconds cooldown between coin collections

-- Coin sound asset ID
local coinSoundId = "rbxassetid://3125624765"

-- Function to play the coin sound
local function playCoinSound()
    local coinSound = Instance.new("Sound")
    coinSound.SoundId = coinSoundId
    coinSound.Volume = 0.2
    coinSound.PlayOnRemove = true
    coinSound.Parent = Player:WaitForChild("PlayerGui")
    coinSound:Destroy() -- `PlayOnRemove` ensures the sound plays
end

-- Function to create the UI
local function createUI()
    if Player:FindFirstChild("PlayerGui"):FindFirstChild("CoinsDisplay") then
        return
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CoinsDisplay"
    screenGui.Parent = Player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "CoinsFrame"
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = UDim2.new(1, -20, 0, 20)
    frame.Size = UDim2.new(0, 220, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- Add a stroke to the frame
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 2
    uiStroke.Color = Color3.fromRGB(255, 215, 0)
    uiStroke.Parent = frame

    local coinLabel = Instance.new("TextLabel")
    coinLabel.Name = "CoinLabel"
    coinLabel.Size = UDim2.new(1, -10, 1, -10)
    coinLabel.Position = UDim2.new(0, 5, 0, 5)
    coinLabel.BackgroundTransparency = 1
    coinLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextScaled = true
    coinLabel.Text = "Coins: 0"
    coinLabel.Parent = frame

    -- Add text shadow effect
    local textShadow = Instance.new("TextLabel")
    textShadow.Size = coinLabel.Size
    textShadow.Position = coinLabel.Position
    textShadow.BackgroundTransparency = 1
    textShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
    textShadow.Font = coinLabel.Font
    textShadow.TextScaled = coinLabel.TextScaled
    textShadow.Text = coinLabel.Text
    textShadow.ZIndex = coinLabel.ZIndex - 1
    textShadow.Parent = frame

    coinLabel:GetPropertyChangedSignal("Text"):Connect(function()
        textShadow.Text = coinLabel.Text
    end)
end

-- Function to update the coin count locally
local coinCount = 0
local function updateCoinCount(amount)
    coinCount = amount
    local coinLabel = Player:FindFirstChild("PlayerGui"):FindFirstChild("CoinsDisplay")
        and Player.PlayerGui.CoinsDisplay:FindFirstChild("CoinsFrame"):FindFirstChild("CoinLabel")
    if coinLabel then
        coinLabel.Text = "Coins: " .. coinCount
    end
end

local function incrementCoinCount(amount)
    coinCount = coinCount + amount
    updateCoinCount(coinCount)
end

local function fetchInitialCoins()
    task.wait(0.1)

    local success, inventory = pcall(function()
        return fetchInventoryFunction:InvokeServer()
    end)

    if success and inventory then
        if inventory.coins then
            updateCoinCount(inventory.coins)
        else
            warn("No coins data in fetched inventory.")
        end
    else
        warn("Failed to fetch initial inventory.")
    end
end

-- Recreate UI and fetch initial coins on respawn
Player.CharacterAdded:Connect(function()
    task.wait(0.1)
    createUI()
    fetchInitialCoins()
end)

-- Initial UI creation and coin fetching
createUI()
fetchInitialCoins()

-- Detect coin collection
local Workspace = game:GetService("Workspace")
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Coin" then
        child.Touched:Connect(function(hit)
            if hit.Parent == Player.Character then
                local currentTime = tick()
                if currentTime - lastCoinCollectionTime >= coinCollectionCooldown then
                    lastCoinCollectionTime = currentTime
                    addCoinsEvent:FireServer(1) -- Notify the server to add coins
                    child:Destroy() -- Remove the coin from the workspace
                end
            end
        end)
    end
end)

-- Listen for coin updates from the server
addCoinsEvent.OnClientEvent:Connect(function(newAmount)
    incrementCoinCount(newAmount)
    playCoinSound()
end)
