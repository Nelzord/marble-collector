local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for adding coins
local addCoinsEvent = ReplicatedStorage:WaitForChild("AddCoinsEvent")

-- Coin spawn settings
local coinModel = Instance.new("Part")
coinModel.Shape = Enum.PartType.Ball
coinModel.Size = Vector3.new(2, 2, 2) -- Small ball
coinModel.BrickColor = BrickColor.new("Bright yellow")
coinModel.Material = Enum.Material.SmoothPlastic
coinModel.Anchored = false
coinModel.CanCollide = true
coinModel.Name = "Coin"

-- Set the spawn area
local spawnRegion = {
    minX = -50,
    maxX = 50,
    minY = 5,
    maxY = 5,
    minZ = -50,
    maxZ = 50,
}

-- Function to spawn a coin
local function spawnCoin()
    local coin = coinModel:Clone()
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
            coin:Destroy()
        end
    end)

    coin.Parent = Workspace
end

-- Spawn coins periodically
while true do
    spawnCoin()
    wait(5) -- Spawn a coin every 5 seconds (adjust as needed)
end
