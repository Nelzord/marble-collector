local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "JumpRequestEvent"
remoteEvent.Parent = ReplicatedStorage

local marbleColorChangeEvent = Instance.new("RemoteEvent")
marbleColorChangeEvent.Name = "MarbleColorChangeEvent"
marbleColorChangeEvent.Parent = ReplicatedStorage

-- Set workspace gravity to Earth's gravity
workspace.Gravity = 1000-- Adjusted to Earth's gravity (9.81 m/s² scaled to Roblox's system)

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local HRP = char:WaitForChild("HumanoidRootPart")
        local Hum = char:WaitForChild("Humanoid")

        -- Create the marble
        local marble = Instance.new("Part")
        marble.Size = Vector3.new(8, 8, 8)
        marble.BrickColor = BrickColor.Random()
        marble.Transparency = 0.5
        marble.Shape = Enum.PartType.Ball
        marble.Material = Enum.Material.SmoothPlastic
        marble.Parent = char

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

        -- Handle marble color change
        marbleColorChangeEvent.OnServerEvent:Connect(function(plr, selectedColor)
            if plr == player then
                marble.Color = selectedColor
                print(plr.Name .. " changed their marble to color:", tostring(selectedColor))
            end
        end)

        -- Handle movement
        game:GetService("RunService").Heartbeat:Connect(function()
            local moveDirection = char.Humanoid.MoveDirection

            -- Calculate target angular velocity based on move direction
            local targetAngularVelocity = Vector3.new(
                moveDirection.Z * 20, -- Reduced for smoother rotation
                0,
                moveDirection.X * -20
            )

            -- Uncomment for spinning effect
            -- Velocity.AngularVelocity = targetAngularVelocity

            -- Set BodyVelocity to move the marble in the desired direction
            BodyVelocity.Velocity = moveDirection * 40 -- Adjust speed as necessary

            -- Enable torque only when moving
            if moveDirection.Magnitude == 0 then
                Velocity.MaxTorque = Vector3.zero
                BodyVelocity.Velocity = Vector3.zero
            else
                Velocity.MaxTorque = Vector3.new(30000, 30000, 30000)
            end
        end)

        -- Replace the groundCheck logic with Raycasting
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

                    -- Apply the jump impulse
                    marble:ApplyImpulse(Vector3.new(0, jumpForce, 0))

                    -- Re-enable the Weld after a short delay
                    task.wait(0.001) -- Adjust the delay as necessary
                    Weld.Enabled = true

                    print("Jump simulated on surface:", result.Instance.Name)
                end
            end
        end)
    end)
end)
