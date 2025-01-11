-- src/server/MarbleShopServer.lua

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

-- Ensure the RemoteEvent exists
local remoteEvent = replicatedStorage:FindFirstChild("OpenMarbleShop")
if not remoteEvent then
    remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = "OpenMarbleShop"
    remoteEvent.Parent = replicatedStorage
    print("Created RemoteEvent: OpenMarbleShop")
end

-- Access the shared Marbles module
local marblesData = require(replicatedStorage.Shared.Marbles)

-- Ensure the RemoteEvents exist
local basicRollEvent = replicatedStorage:FindFirstChild("BasicRollEvent") or Instance.new("RemoteEvent", replicatedStorage)
basicRollEvent.Name = "BasicRollEvent"

local rareRollEvent = replicatedStorage:FindFirstChild("RareRollEvent") or Instance.new("RemoteEvent", replicatedStorage)
rareRollEvent.Name = "RareRollEvent"

local legendaryRollEvent = replicatedStorage:FindFirstChild("LegendaryRollEvent") or Instance.new("RemoteEvent", replicatedStorage)
legendaryRollEvent.Name = "LegendaryRollEvent"

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
    interactionPart.Position = marbleMachinePosition - Vector3.new(0, 25, 0) -- Offset by 25 studs downward on the Y-axis

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
    prompt.MaxActivationDistance = 50 -- Set activation distance to 50
    prompt.RequiresLineOfSight = false -- Disable line of sight for flexibility
    prompt.Parent = interactionPart
    print("Created ProximityPrompt in InteractionPart")
end

local function rollMarble(player, rollType)
    -- Define the rarity mappings for each roll type
    local rarityMapping = {
        Basic = {"Common", "Uncommon", "Rare", "Epic"},
        Rare = {"Rare", "Epic"},
        Legendary = {"Epic", "Legendary", "Transcendent"}
    }

    -- Get the rarities for the given rollType
    local rarities = rarityMapping[rollType]
    if not rarities then
        error("Invalid roll type: " .. tostring(rollType))
    end

    -- Filter marbles by allowed rarities
    local filteredMarbles = {}
    for _, marble in ipairs(marblesData) do
        if table.find(rarities, marble.Rarity) then
            table.insert(filteredMarbles, marble)
        end
    end

    -- Ensure there are marbles to roll
    if #filteredMarbles == 0 then
        warn("No marbles available for roll type: " .. rollType)
        return nil
    end

    -- Choose a random marble from the filtered list
    local selectedMarble = filteredMarbles[math.random(1, #filteredMarbles)]
    print(player.Name .. " rolled and received: " .. selectedMarble.Name)
    return selectedMarble
end


-- Connect RemoteEvents to handle rolls
basicRollEvent.OnServerEvent:Connect(function(player)
    local rarities = {"Common", "Uncommon", "Rare", "Epic"}
    local result = rollMarble(player, "Basic")
    basicRollEvent:FireClient(player, result) -- Send the result back to the client
end)

rareRollEvent.OnServerEvent:Connect(function(player)
    local rarities = {"Rare", "Epic"}
    local result = rollMarble(player, "Rare")
    rareRollEvent:FireClient(player, result) -- Send the result back to the client
end)

legendaryRollEvent.OnServerEvent:Connect(function(player)
    local rarities = {"Epic", "Legendary", "Transcendent"}
    local result = rollMarble(player, "Legendary")
    legendaryRollEvent:FireClient(player, result) -- Send the result back to the client
end)

-- Connect the Triggered event
prompt.Triggered:Connect(function(player)
    print(player.Name .. " activated the ProximityPrompt!")
    remoteEvent:FireClient(player)
end)

-- Listen for roll requests from the client
remoteEvent.OnServerEvent:Connect(function(player, rollType)
    rollMarble(player, rollType)
end)
