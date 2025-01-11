-- Reference necessary services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get the local player
local player = Players.LocalPlayer

-- Wait for the RemoteEvent in ReplicatedStorage
local deathSoundEvent = ReplicatedStorage:WaitForChild("DeathSoundEvent")

-- Create the death sound instance
local deathSound = Instance.new("Sound")
deathSound.SoundId = "rbxassetid://9119594928" -- Replace with your valid sound asset ID
deathSound.Volume = 0.25 -- Adjust the volume as needed
deathSound.Parent = player:WaitForChild("PlayerGui") -- Parent the sound to PlayerGui for local playback

-- Connect to the RemoteEvent to play the sound when fired
deathSoundEvent.OnClientEvent:Connect(function()
    -- Play the death sound
    deathSound:Play()
end)
