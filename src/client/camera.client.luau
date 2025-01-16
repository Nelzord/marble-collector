local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = ReplicatedStorage:WaitForChild("JumpRequestEvent")

-- Detect when the player presses the jump key
userInputService.InputBegan:Connect(function(input, gameProcessed)
    print("key press", input.KeyCode)
    if gameProcessed then return end -- Ignore if the game already processed this input
    if input.KeyCode == Enum.KeyCode.Space then
        print("JumpRequestEvent sent")
        -- Send a jump request to the server
        remoteEvent:FireServer()
    end
end)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Wait for the player's character and marble
local function getMarble()
    local character = player.Character or player.CharacterAdded:Wait()
    return character:WaitForChild("Marble")
end

-- Set up the camera to follow the marble
local function setupCamera()
    local camera = workspace.CurrentCamera
    camera.CameraSubject = nil -- Start with no subject until the marble is found

    local marble = getMarble()

    if marble then
        camera.CameraType = Enum.CameraType.Custom -- Default Roblox mouse camera control
        camera.CameraSubject = marble -- Set the marble as the camera's subject
    end
end

-- Set up the camera when the character spawns
player.CharacterAdded:Connect(function()
    task.wait(1) -- Small delay to ensure everything is loaded
    setupCamera()
end)

-- Initial setup in case the character is already loaded
if player.Character then
    setupCamera()
end
