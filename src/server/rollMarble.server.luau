local replicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = replicatedStorage:FindFirstChild("OpenMarbleShop")

-- Ensure the RemoteEvent exists
if not remoteEvent then
    remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = "OpenMarbleShop"
    remoteEvent.Parent = replicatedStorage
    print("Created RemoteEvent: OpenMarbleShop")
end

-- Locate MarbleMachine
local lobbyItems = workspace:WaitForChild("LobbyItems")
local marbleMachine = lobbyItems:WaitForChild("MarbleMachine")

if not marbleMachine then
    error("MarbleMachine not found in Workspace > LobbyItems")
end

-- Check or create an InteractionPart
local interactionPart = marbleMachine:FindFirstChild("InteractionPart")
if not interactionPart then
    interactionPart = Instance.new("Part")
    interactionPart.Name = "InteractionPart"
    interactionPart.Size = Vector3.new(10, 10, 10) -- Define the size of the interaction zone
    interactionPart.Transparency = 1 -- Make it invisible
    interactionPart.CanCollide = false -- Allow players to walk through it
    interactionPart.Anchored = true -- Ensure it doesn't move

    -- Position the part slightly below the MarbleMachine
    local marbleMachinePosition = marbleMachine:GetModelCFrame().p -- Get the center position of the model
    interactionPart.Position = marbleMachinePosition - Vector3.new(0, 25, 0) -- Offset by 5 studs downward on the Y-axis

    interactionPart.Parent = marbleMachine
    print("Created InteractionPart below MarbleMachine")
end

-- Check for or create the ProximityPrompt
local prompt = interactionPart:FindFirstChild("ProximityPrompt")
if not prompt then
    prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ProximityPrompt"
    prompt.ActionText = "Open Marble Shop"
    prompt.ObjectText = "Marble Machine"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 50 -- Set activation distance to 100
    prompt.RequiresLineOfSight = false -- Disable line of sight for flexibility
    prompt.Parent = interactionPart
    print("Created ProximityPrompt in InteractionPart")
end

-- Connect the Triggered event
prompt.Triggered:Connect(function(player)
    print(player.Name .. " activated the ProximityPrompt!")
    remoteEvent:FireClient(player)
end)
