local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for adding coins
local addCoinsEvent = ReplicatedStorage:WaitForChild("AddCoinsEvent")

-- Set the spawn area
local spawnRegion = {
    minX = -50,
    maxX = 50,
    minY = 5,
    maxY = 5,
    minZ = -50,
    maxZ = 50,
}

-- Maximum number of coins allowed in the workspace at once
local maxCoins = 5
local currentCoins = {}

-- Function to create a realistic coin
local function createCoin()
    local coin = Instance.new("Part")
    coin.Shape = Enum.PartType.Cylinder -- Set shape to cylinder
    coin.Size = Vector3.new(.5, 7, 7) -- Larger coin size (diameter, thickness)
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
        coin.Position = Vector3.new(coin.Position.X, initialY + hoverOffset, coin.Position.Z)

        -- Spinning effect
        coin.Orientation = coin.Orientation + Vector3.new(0, spinSpeed * deltaTime, 0)
    end)
end

-- Function to spawn a coin in the workspace
local function spawnCoin()
    -- Ensure the number of coins does not exceed the maximum
    if #currentCoins >= maxCoins then
        return
    end

    local coin = createCoin()
    coin.Position = Vector3.new(
        math.random(spawnRegion.minX, spawnRegion.maxX),
        math.random(spawnRegion.minY, spawnRegion.maxY),
        math.random(spawnRegion.minZ, spawnRegion.maxZ)
    )

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
