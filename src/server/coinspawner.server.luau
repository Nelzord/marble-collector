local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for adding coins
local addCoinsEvent = ReplicatedStorage:WaitForChild("AddCoinsEvent")

-- Maximum number of coins allowed in the workspace at once
local maxCoins = 20
local currentCoins = {}

-- Folder containing level subfolders
local levelsFolder = Workspace:WaitForChild("Levels")

-- Height above the plate where coins spawn
local spawnHeight = 3 -- Adjust as needed to allow characters to walk up

-- Variance in random X/Z position
local spawnVariance = 50 -- Variance in studs for X/Z position

-- Function to get a random spawn position around a LevelXPlate
local function getRandomSpawnPosition(plate)
    local platePosition = plate.Position

    -- Randomize X/Z positions with the given variance
    local randomX = platePosition.X + math.random(-spawnVariance, spawnVariance)
    local randomZ = platePosition.Z + math.random(-spawnVariance, spawnVariance)

    -- Return the calculated spawn position above the plate
    return Vector3.new(randomX, platePosition.Y + spawnHeight, randomZ)
end

-- Function to create a realistic coin
local function createCoin()
    local coin = Instance.new("Part")
    coin.Shape = Enum.PartType.Cylinder -- Set shape to cylinder
    coin.Size = Vector3.new(0.5, 7, 7) -- Coin size (thickness, diameter)
    coin.BrickColor = BrickColor.new("Bright yellow") -- Gold color
    coin.Material = Enum.Material.SmoothPlastic -- Smooth, shiny appearance
    coin.Anchored = true -- Anchor to make it hover
    coin.CanCollide = false -- Players can pass through it
    coin.Name = "Coin"

    return coin
end

-- Function to make the coin hover and spin
local function animateCoin(coin)
    -- Hovering animation
    local initialY = coin.Position.Y
    local hoverAmplitude = 0.5 -- How much the coin moves up and down
    local hoverSpeed = 2 -- Speed of hovering

    -- Spinning animation
    local spinSpeed = 90 -- Degrees per second

    -- Update function
    game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        -- Hovering effect
        local hoverOffset = math.sin(tick() * hoverSpeed) * hoverAmplitude
        coin.Position = Vector3.new(coin.Position.X, initialY + 10, coin.Position.Z)

        -- Spinning effect
        coin.Orientation = coin.Orientation + Vector3.new(0, spinSpeed * deltaTime, 0)
    end)
end

-- Function to spawn a coin near a random LevelXPlate
local function spawnCoin()
    -- Ensure the number of coins does not exceed the maximum
    if #currentCoins >= maxCoins then
        return
    end

    -- Get all LevelXPlates in the Levels folder
    local plates = {}
    for _, levelFolder in pairs(levelsFolder:GetChildren()) do
        if levelFolder:IsA("Folder") then
            for _, plate in pairs(levelFolder:GetChildren()) do
                if plate:IsA("BasePart") and plate.Name:match("Level%dPlate") then
                    table.insert(plates, plate)
                end
            end
        end
    end

    -- Select a random plate
    if #plates == 0 then
        warn("No LevelXPlates found for coin spawning.")
        return
    end
    local selectedPlate = plates[math.random(1, #plates)]

    -- Calculate spawn position
    local spawnPosition = getRandomSpawnPosition(selectedPlate)

    -- Log the plate name and spawn position
    print(string.format("Coin spawned near plate: %s at position: (%.2f, %.2f, %.2f)",
        selectedPlate.Name, spawnPosition.X, spawnPosition.Y, spawnPosition.Z))

    -- Create and position the coin
    local coin = createCoin()
    coin.Position = spawnPosition

    -- Add touch functionality to the coin
    coin.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            -- Give the player a coin
            addCoinsEvent:FireClient(player, 1) -- Adds 1 coin

            -- Remove the coin from the workspace and the currentCoins table
            coin:Destroy()
            for i, c in ipairs(currentCoins) do
                if c == coin then
                    table.remove(currentCoins, i)
                    break
                end
            end
        end
    end)

    -- Add the coin to the currentCoins table
    table.insert(currentCoins, coin)

    -- Parent the coin to the workspace
    coin.Parent = Workspace

    -- Animate the coin
    animateCoin(coin)
end

-- Spawn coins periodically
while true do
    spawnCoin()
    wait(10) -- Spawn a coin every 10 seconds (adjust as needed)
end
