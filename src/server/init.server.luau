local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace") 

-- Create the RemoteEvent
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "JumpRequestEvent"
remoteEvent.Parent = ReplicatedStorage

local marbleTextureChangeEvent = Instance.new("RemoteEvent")
marbleTextureChangeEvent.Name = "MarbleTextureChangeEvent"
marbleTextureChangeEvent.Parent = ReplicatedStorage

-- Set workspace gravity to Earth's gravity
workspace.Gravity = 1000-- Adjusted to Earth's gravity (9.81 m/s² scaled to Roblox's system)


local function changeMarbleTexture(marble, textureId)
    -- Validate input
    if not textureId then
        warn("No TextureId provided for the marble object.")
        return
    end

    -- Remove existing Decals
    for _, child in ipairs(marble:GetChildren()) do
        if child:IsA("Decal") then
            child:Destroy()
        end
    end

    -- Apply decals to all sides of the marble
    for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
        local decal = Instance.new("Decal")
        decal.Texture = textureId -- Use the provided TextureId
        decal.Face = face -- Apply to each face
        decal.Parent = marble
    end

    print("Applied texture to marble using Decals with TextureId:", textureId)
end

marbleTextureChangeEvent.OnServerEvent:Connect(function(player, textureId)
    local character = player.Character or player.CharacterAdded:Wait()
    local marble = character:FindFirstChild("Marble") -- Replace with your marble object name

    if marble then
        changeMarbleTexture(marble, textureId) -- Call the texture change function
        print(player.Name .. " changed their marble's texture to:", textureId)
    else
        warn("Marble object not found for player:", player.Name)
    end
end)

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local HRP = char:WaitForChild("HumanoidRootPart")
        local Hum = char:WaitForChild("Humanoid")

        -- Create the marble
        local marble = Instance.new("Part")
        marble.Name = "Marble"
        marble.Size = Vector3.new(8, 8, 8)
        marble.BrickColor = BrickColor.Black()
        marble.Transparency = 0
        marble.Shape = Enum.PartType.Ball
        marble.Material = Enum.Material.SmoothPlastic
        marble.Parent = char
        changeMarbleTexture(marble, "rbxassetid://80502554386009")

        -- Position the marble above the baseplate by the character's height
        local characterHeight = (Hum.HipHeight * 2) + 5 -- Adjust as necessary
        marble.Position = HRP.Position + Vector3.new(0, characterHeight, 0)

        -- Add angular velocity to the marble
        local Velocity = Instance.new("BodyAngularVelocity")
        Velocity.MaxTorque = Vector3.new(30000, 30000, 30000)
        Velocity.AngularVelocity = Vector3.zero
        Velocity.Parent = marble

        -- Add a BodyForce to simulate gravity
        local BodyForce = Instance.new("BodyForce")
        BodyForce.Force = Vector3.new(0, marble:GetMass() * workspace.Gravity, 0)
        BodyForce.Parent = marble

        -- Add a BodyVelocity for directional movement
        local BodyVelocity = Instance.new("BodyVelocity")
        BodyVelocity.MaxForce = Vector3.new(100000, 0, 100000) -- Allow movement on X and Z axes
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.Parent = marble

        -- Weld the marble to the character
        local Weld = Instance.new("Weld")
        Weld.Parent = marble
        Weld.Part0 = HRP
        Weld.Part1 = marble

        -- Set the character to PlatformStand to prevent walking
        Hum.PlatformStand = true

        -- Handle movement
        local lastVelocity = Vector3.zero -- Tracks the marble's last velocity
        game:GetService("RunService").Heartbeat:Connect(function()
            local moveDirection = char.Humanoid.MoveDirection

            -- Calculate target angular velocity based on move direction
            local targetAngularVelocity = Vector3.new(
                moveDirection.Z * 20, -- Reduced for smoother rotation
                0,
                moveDirection.X * -20
            )

            -- Set the marble's angular velocity
            Velocity.AngularVelocity = targetAngularVelocity

            -- Set BodyVelocity to move the marble in the desired direction
            if moveDirection.Magnitude > 0 then
                BodyVelocity.Velocity = moveDirection * 40 -- Adjust speed as necessary
                lastVelocity = BodyVelocity.Velocity -- Update lastVelocity when actively moving
            else
                -- Gradually slow down the marble using friction
                lastVelocity = lastVelocity * 0.95 -- Apply friction effect (adjust 0.95 as needed)
                BodyVelocity.Velocity = lastVelocity

                -- Stop completely when the velocity is very small
                if lastVelocity.Magnitude < 0.1 then
                    BodyVelocity.Velocity = Vector3.zero
                    lastVelocity = Vector3.zero
                end
            end

            -- Enable torque only when moving
            if BodyVelocity.Velocity.Magnitude == 0 then
                Velocity.MaxTorque = Vector3.zero
            else
                Velocity.MaxTorque = Vector3.new(30000, 30000, 30000)
            end
        end)

        remoteEvent.OnServerEvent:Connect(function(plr)
            if plr == player then
                -- Raycast downward to check if the marble is grounded
                local rayOrigin = marble.Position
                local rayDirection = Vector3.new(0, -5, 0) -- Adjust ray length as needed
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {marble, char} -- Ignore marble and character
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        
                local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
                -- If the ray hits a surface, the marble is grounded
                if result then
                    local jumpForce = 5000 -- Adjust the jump force as needed
        
                    -- Disable and remove the Weld
                    Weld.Enabled = false
        
                    -- Make the player's character invisible
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1 -- Make the part invisible
                        elseif part:IsA("Decal") then
                            part.Transparency = 1 -- Make decals invisible as well
                        end
                    end
        
                    -- Apply the jump impulse
                    marble:ApplyImpulse(Vector3.new(0, jumpForce, 0))
        
                    -- Re-enable the Weld after a short delay
                    task.wait(0.005) -- Adjust the delay as necessary
                    Weld.Enabled = true
        
                    -- Restore the player's character visibility
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 0 -- Restore visibility
                        elseif part:IsA("Decal") then
                            part.Transparency = 0 -- Restore decal visibility
                        end
                    end
        
                    print("Jump simulated on surface:", result.Instance.Name)
                end
            end
        end)
        
    end)
end)


local TeleportToLevelEvent = Instance.new("RemoteEvent", ReplicatedStorage)
TeleportToLevelEvent.Name = "TeleportToLevelEvent"

-- Function to find a child recursively in Workspace
local function findObjectInWorkspace(objectName)
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant.Name == objectName then
            return descendant
        end
    end
    return nil
end

-- Function to teleport the player
local function teleportPlayerToLevel(player, levelLocation)
    local levelObject = findObjectInWorkspace(levelLocation) -- Use the recursive search function
    
    if levelObject and levelObject:IsA("BasePart") then
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.CFrame = levelObject.CFrame + Vector3.new(0, 5, 0) -- Teleport above the level object
        print(player.Name .. " teleported to " .. levelLocation)
    else
        warn("Level object not found or is not a BasePart: " .. tostring(levelLocation))
    end
end





-- Connect the RemoteEvent
TeleportToLevelEvent.OnServerEvent:Connect(teleportPlayerToLevel)