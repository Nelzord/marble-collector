local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local textures = { "rbxassetid://12345678", "rbxassetid://87654321", "rbxassetid://23456789" } -- Replace with actual texture IDs

local ballSettings = {
    size = Vector3.new(12, 12, 12),
    color = Color3.new(1, 1, 1), -- Standard white color
    material = Enum.Material.SmoothPlastic,
    friction = 0.5,
    density = 1,
}

local function createBall(player)
    local ball = Instance.new("Part")
    ball.Name = player.Name .. "'s Ball"
    ball.Shape = Enum.PartType.Ball
    ball.Size = ballSettings.size
    ball.Color = ballSettings.color
    ball.Material = ballSettings.material
    ball.Anchored = false
    ball.CanCollide = true
    ball.CustomPhysicalProperties = PhysicalProperties.new(
        ballSettings.density,
        ballSettings.friction,
        0.5, -- Elasticity
        ballSettings.friction,
        0.5 -- Friction weight
    )
    ball.Position = Vector3.new(0, 15, 0)
    ball.Parent = workspace

    -- Apply random texture
    local texture = Instance.new("Decal")
    texture.Texture = textures[math.random(#textures)]
    texture.Face = Enum.NormalId.Top
    texture.Parent = ball

    return ball
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        -- Disable character movement
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0

        -- Create a ball and weld the character inside it
        local ball = createBall(player)
        character:SetPrimaryPartCFrame(CFrame.new(ball.Position))

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                part.CanCollide = false
            end
        end

        -- Weld the character to the ball
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = ball
        weld.Part1 = character.PrimaryPart
        weld.Parent = ball
    end)
end)

-- Handle velocity updates from the client
local updateBallVelocity = Instance.new("RemoteEvent")
updateBallVelocity.Name = "UpdateBallVelocity"
updateBallVelocity.Parent = ReplicatedStorage

updateBallVelocity.OnServerEvent:Connect(function(player, velocity, isJumping)
    local ball = workspace:FindFirstChild(player.Name .. "'s Ball")
    if ball then
        ball.AssemblyLinearVelocity = velocity
        if isJumping then
            ball:ApplyImpulse(Vector3.new(0, ball:GetMass() * 100, 0)) -- Apply jump force
        end
    end
end)

-- Adjust ground friction
workspace.Baseplate.CustomPhysicalProperties = PhysicalProperties.new(
    1, -- Density
    0.5, -- Friction
    0.5, -- Elasticity
    0.5, -- Friction weight
    0.5 -- Elasticity weight
)
