-- Reference ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Reference the InventoryUpdateEvent
local inventoryUpdateEvent = ReplicatedStorage:WaitForChild("InventoryUpdateEvent")

-- Create a ScreenGui for the notification
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationGui"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Create a template for the notification
local notificationTemplate = Instance.new("TextLabel")
notificationTemplate.Size = UDim2.new(0.4, 0, 0.1, 0)
notificationTemplate.Position = UDim2.new(0.3, 0, 0.45, 0)
notificationTemplate.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
notificationTemplate.BackgroundTransparency = 0.3
notificationTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationTemplate.Font = Enum.Font.SourceSansBold
notificationTemplate.TextSize = 36
notificationTemplate.Visible = false
notificationTemplate.Parent = screenGui

-- Load and play a success sound
local successSound = Instance.new("Sound")
successSound.SoundId = "rbxassetid://2789427964" -- Replace with a valid sound asset ID
successSound.Volume = 0.25
successSound.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Function to show a marble unlock notification
local function showNotification(marbleName)
    local notification = notificationTemplate:Clone()
    notification.Text = "You unlocked: " .. marbleName .. "!"
    notification.Visible = true
    notification.Parent = screenGui

    -- Play the success sound
    successSound:Play()

    -- Additional logic for Speedy Red
    if marbleName == "Speedy Red" then
        local secondaryNotification = notificationTemplate:Clone()
        secondaryNotification.Text = "Select new marble from inventory!"
        secondaryNotification.Size = UDim2.new(0.3, 0, 0.08, 0)
        secondaryNotification.Position = UDim2.new(0.35, 0, 0.55, 0)
        secondaryNotification.Visible = true
        secondaryNotification.Parent = screenGui

        -- Fade out and remove the secondary notification
        task.delay(3, function()
            for i = 0, 1, 0.1 do
                secondaryNotification.TextTransparency = i
                secondaryNotification.BackgroundTransparency = i + 0.3
                task.wait(0.1)
            end
            secondaryNotification:Destroy()
        end)
    end

    -- Fade out and remove the main notification
    task.delay(3, function()
        for i = 0, 1, 0.1 do
            notification.TextTransparency = i
            notification.BackgroundTransparency = i + 0.3
            task.wait(0.1)
        end
        notification:Destroy()
    end)
end

-- Listen for the InventoryUpdateEvent
inventoryUpdateEvent.OnClientEvent:Connect(function(updateType, marbleName)
    if updateType == "MarbleUnlocked" and marbleName then
        showNotification(marbleName)
    end
end)
