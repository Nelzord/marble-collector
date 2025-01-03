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

        -- Set the character to PlatformStand to prevent regular walking
        Hum.PlatformStand = true

        -- Camera follows the torso
        local camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Scriptable

        game:GetService("RunService").Heartbeat:Connect(function()
            local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
            if torso then
                local cameraOffset = Vector3.new(0, 10, 20) -- Fixed offset above and behind the torso
                local targetPosition = torso.Position + cameraOffset
                camera.CFrame = CFrame.new(camera.CFrame.Position:Lerp(targetPosition, 0.1), torso.Position) -- Smoother camera transitions
            end
        end)

        -- Control the marble's movement smoothly
        local function lerp(a, b, t)
            return a + (b - a) * t
        end

        local targetAngularVelocity = Vector3.zero
        local smoothingFactor = 0.05 -- Increased for much smoother transitions
        local moveSpeed = 40 -- Adjusted for smoother movement

        -- Ensure marble has mass to interact properly with physics
        marble.Massless = false

        game:GetService("RunService").Heartbeat:Connect(function()
            local moveDirection = char.Humanoid.MoveDirection

            -- Calculate target angular velocity based on move direction
            targetAngularVelocity = Vector3.new(
                moveDirection.Z * 20, -- Reduced for smoother rotation
                0,
                moveDirection.X * -20
            )
            -- uncomment for spinning
            -- -- Update angular velocity smoothly
            -- Velocity.AngularVelocity = Vector3.new(
            --     lerp(Velocity.AngularVelocity.X, targetAngularVelocity.X, smoothingFactor),
            --     lerp(Velocity.AngularVelocity.Y, targetAngularVelocity.Y, smoothingFactor),
            --     lerp(Velocity.AngularVelocity.Z, targetAngularVelocity.Z, smoothingFactor)
            -- )

            -- Set BodyVelocity to move the marble in the desired direction
            BodyVelocity.Velocity = moveDirection * moveSpeed -- Adjust speed as necessary

            -- Enable torque only when moving
            if moveDirection.Magnitude == 0 then
                Velocity.MaxTorque = Vector3.zero
                BodyVelocity.Velocity = Vector3.zero
            else
                Velocity.MaxTorque = Vector3.new(30000, 30000, 30000)
            end
        end)
    end)
end)
