local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local playerInventoryDataStore = DataStoreService:GetDataStore("PlayerInventory")


-- Create RemoteEvents for inventory updates
local inventoryUpdateEvent = Instance.new("RemoteEvent")
inventoryUpdateEvent.Name = "InventoryUpdateEvent"
inventoryUpdateEvent.Parent = ReplicatedStorage

local fetchInventoryFunction = Instance.new("RemoteFunction")
fetchInventoryFunction.Name = "FetchInventoryFunction"
fetchInventoryFunction.Parent = ReplicatedStorage

local playerInventories = {} -- Store player inventories in memory

-- Load Marbles Data
local Marbles = require(ReplicatedStorage.Shared.Marbles)

-- Function to print a player's inventory
local function printInventory(player)
    local inventory = playerInventories[player.UserId]
    if inventory then
        print("=== Inventory for " .. player.Name .. " ===")
        print("Beaten Levels:")
        if #inventory.beatenLevels > 0 then
            for _, level in ipairs(inventory.beatenLevels) do
                print("- " .. level)
            end
        else
            print("No levels beaten yet.")
        end

        print("Unlocked Marbles:")
        if #inventory.unlockedMarbles > 0 then
            for _, marble in ipairs(inventory.unlockedMarbles) do
                print("- " .. marble)
            end
        else
            print("No marbles unlocked yet.")
        end
        print("=== End of Inventory ===")
    else
        print("No inventory found for player: " .. player.Name)
    end
end

-- Function to load player inventory from DataStore
local function loadPlayerInventory(player)
    local inventory = {
        beatenLevels = {}, -- Track completed levels
        unlockedMarbles = {}, -- Track unlocked marbles
    }
    
    local success, data = pcall(function()
        playerInventoryDataStore:RemoveAsync(player.UserId)
        return playerInventoryDataStore:GetAsync(player.UserId)
    end)
    
    if success and data then
        inventory = data
    end

    -- Ensure the default marble is in the inventory
    if not table.find(inventory.unlockedMarbles, "DefaultMarble") then
        table.insert(inventory.unlockedMarbles, "DefaultMarble")
    end
    
    playerInventories[player.UserId] = inventory
    printInventory(player)
    return inventory
end

-- Function to save player inventory to DataStore
local function savePlayerInventory(player)
    local inventory = playerInventories[player.UserId]
    if inventory then
        pcall(function()
            playerInventoryDataStore:SetAsync(player.UserId, inventory)
        end)
    end
end

-- Function to unlock a marble
local function unlockMarble(player, marbleName)
    local inventory = playerInventories[player.UserId]
    if inventory and not table.find(inventory.unlockedMarbles, marbleName) then
        table.insert(inventory.unlockedMarbles, marbleName)
        inventoryUpdateEvent:FireClient(player, "MarbleUnlocked", marbleName)
        savePlayerInventory(player)
    end
end

-- Function to unlock all marbles for a player
local function unlockAllMarbles(player)
    local inventory = playerInventories[player.UserId]
    if not inventory then
        warn("No inventory found for player: " .. player.Name)
        return
    end

    for _, marbleData in ipairs(Marbles) do
        if not table.find(inventory.unlockedMarbles, marbleData.Name) then
            table.insert(inventory.unlockedMarbles, marbleData.Name)
            inventoryUpdateEvent:FireClient(player, "MarbleUnlocked", marbleData.Name)
            print(player.Name .. " unlocked marble: " .. marbleData.Name)
        end
    end

    -- Save the updated inventory to the DataStore
    savePlayerInventory(player)
end

-- Example usage:
game.Players.PlayerAdded:Connect(function(player)
    -- Unlock all marbles for the player upon joining (for testing purposes)
    player.CharacterAdded:Connect(function()
        -- unlockAllMarbles(player)
    end)
end)

-- Function to check if a player owns a gamepass
local function playerOwnsGamepass(player, gamepassId)
    local success, result = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
    end)
    if success then
        return result
    else
        warn("Failed to check gamepass ownership for player: " .. player.Name)
        return false
    end
end


-- Function to mark a level as beaten and update the inventory
local function completeLevel(player, levelName)
    local inventory = playerInventories[player.UserId]
    if inventory then
        -- Check if the level is already marked as beaten
        if not table.find(inventory.beatenLevels, levelName) then
            table.insert(inventory.beatenLevels, levelName)
            inventoryUpdateEvent:FireClient(player, "LevelCompleted", levelName)
            print(player.Name .. " completed level: " .. levelName)
            printInventory(player)
            -- Save the updated inventory to the DataStore
            savePlayerInventory(player)
        else
            print(player.Name .. " has already completed level: " .. levelName)
        end
    else
        warn("No inventory found for player: " .. player.Name)
    end
end

-- Update the monitorMarble function to handle level completion
local function monitorMarble(player, character)
    -- Get the main part of the character
    local mainPart = character:FindFirstChild("Part") or character:FindFirstChildWhichIsA("BasePart")

    if not mainPart then
        warn("Main part not found for player:", player.Name)
        return
    end

    -- Attach Touched event
    mainPart.Touched:Connect(function(hit)
        if hit then
            -- Handle hazard touch
            if hit.Name.find(hit.Name, "Hazard") then
                print(player.Name .. " touched a Hazard and will die.")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0 -- Kills the player
                end
                return
            end

            if hit.Name == "HazardStatic" or hit.Name == "HazardRotate" then
                print(player.Name .. " touched a Hazard and will die.")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0 -- Kills the player
                end
                return
            end
            
            -- Check if the touched part unlocks a marble
            for _, marbleData in ipairs(Marbles) do
                if marbleData.LevelUnlocked == hit.Name then
                    completeLevel(player, marbleData.LevelUnlocked)
                    print(player.Name .. " unlocked marble:", marbleData.Name, "by touching:", hit.Name)
                end
            end
        else
            print("No part detected on touch event for", player.Name)
        end
    end)
end


game.Players.PlayerAdded:Connect(function(player)
    -- Load the player's inventory upon joining
    local inventory = loadPlayerInventory(player)

    --  -- Unlock all marbles if the player owns the corresponding gamepass
    --  if playerOwnsGamepass(player, 1022595197) then
    --     print(player.Name .. " owns the 'Unlock All Marbles' gamepass.")
    --     unlockAllMarbles(player)
    -- endd
    
    -- Handle the player's character spawning
    player.CharacterAdded:Connect(function(character)
        print(player.Name .. "'s character added.")
        -- Ensure the character is fully loaded
        local success, part = pcall(function()
            return character:WaitForChild("Part", 10) -- Adjust timeout as needed
        end)

        if success and part then
            -- Start monitoring the character as the marble
            if character:IsA("Model") then
                print(player.Name .. "'s character (marble) is ready for monitoring.")
                monitorMarble(player, character)
            else
                warn("Player's character is not a valid Model:", player.Name)
            end
        else
            warn("Character failed to load properly for:", player.Name)
        end
    end)

    -- Check if the character already exists (for scenarios where CharacterAdded doesn't fire immediately)
    if player.Character then
        print(player.Name .. "'s character already exists. Connecting to it.")
        local character = player.Character
        monitorMarble(player, character)
    end
end)

-- Save inventory when the player leaves
game.Players.PlayerRemoving:Connect(function(player)
    savePlayerInventory(player)
    playerInventories[player.UserId] = nil -- Remove from memory
end)

-- Fetch inventory (RemoteFunction)
fetchInventoryFunction.OnServerInvoke = function(player)
    return playerInventories[player.UserId] or {
        beatenLevels = {},
        unlockedMarbles = {"DefaultMarble"}, -- Ensure the default marble is returned
    }
end