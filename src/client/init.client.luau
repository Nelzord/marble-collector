local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ball = Workspace:WaitForChild(player.Name .. "'s Ball")
local camera = Workspace.CurrentCamera

local baseAcceleration = 300 -- Adjusted for balanced movement
local maxVelocity = 750
local jumpPower = 1000 -- Force applied when jumping
local velocity = Vector3.zero
local activeKeys = {}
local isJumping = false

-- Calculate velocity relative to the camera
local function calculateCameraRelativeVelocity(direction)
    local cameraCFrame = camera.CFrame
    local forwardVector = Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z).Unit
    local rightVector = Vector3.new(cameraCFrame.RightVector.X, 0, cameraCFrame.RightVector.Z).Unit

    if direction == "forward" then
        return forwardVector * baseAcceleration
    elseif direction == "backward" then
        return -forwardVector * baseAcceleration
    elseif direction == "left" then
        return -rightVector * baseAcceleration
    elseif direction == "right" then
        return rightVector * baseAcceleration
    end

    return Vector3.zero
end

-- Update ball velocity and send to the server
RunService.RenderStepped:Connect(function()
    local desiredVelocity = Vector3.zero

    if activeKeys["W"] then
        desiredVelocity += calculateCameraRelativeVelocity("forward")
    end
    if activeKeys["S"] then
        desiredVelocity += calculateCameraRelativeVelocity("backward")
    end
    if activeKeys["A"] then
        desiredVelocity += calculateCameraRelativeVelocity("left")
    end
    if activeKeys["D"] then
        desiredVelocity += calculateCameraRelativeVelocity("right")
    end

    velocity = velocity:Lerp(desiredVelocity, 0.2)

    -- Cap velocity
    if velocity.Magnitude > maxVelocity then
        velocity = velocity.Unit * maxVelocity
    end

    -- Send velocity and jump state to the server
    ReplicatedStorage:WaitForChild("UpdateBallVelocity"):FireServer(velocity, isJumping)

    -- Reset jump state after sending
    isJumping = false
end)

-- Track key presses
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    local key = input.KeyCode.Name
    if key == "W" or key == "A" or key == "S" or key == "D" then
        activeKeys[key] = true
    elseif key == "Space" then
        isJumping = true
    end
end)

-- Track key releases
UserInputService.InputEnded:Connect(function(input)
    local key = input.KeyCode.Name
    if activeKeys[key] then
        activeKeys[key] = nil
    end
end)
