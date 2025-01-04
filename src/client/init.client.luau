local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = ReplicatedStorage:WaitForChild("JumpRequestEvent")

-- Detect when the player presses the jump key
userInputService.InputBegan:Connect(function(input, gameProcessed)
    print("key press", input.KeyCode)
    if gameProcessed then return end -- Ignore if the game already processed this input
    if input.KeyCode == Enum.KeyCode.Space then
        -- Send a jump request to the server
        remoteEvent:FireServer()
    end
end)
