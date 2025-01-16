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

-- Add this near your other RemoteEvent creations
local unlockMarbleEvent = Instance.new("RemoteEvent")
unlockMarbleEvent.Name = "UnlockMarbleEvent"
unlockMarbleEvent.Parent = ReplicatedStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local deathSoundEvent = Instance.new("RemoteEvent")
deathSoundEvent.Name = "DeathSoundEvent"
deathSoundEvent.Parent = ReplicatedStorage

-- Create the RemoteEvent for adding coins
local addCoinsEvent = Instance.new("RemoteEvent")
addCoinsEvent.Name = "AddCoinsEvent"
addCoinsEvent.Parent = ReplicatedStorage



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
        print("Coins: " .. (inventory.coins or 0))
        print("=== End of Inventory ===")
    else
        print("No inventory found for player: " .. player.Name)
    end
end

local function loadPlayerInventory(player)
    local defaultInventory = {
        beatenLevels = {},
        unlockedMarbles = {"DefaultMarble"}, -- Default marble
        coins = 0, -- Default coins
    }

    local success, data = pcall(function()
        return playerInventoryDataStore:GetAsync(player.UserId)
    end)

    if success and data then
        -- Merge with default inventory to handle missing keys
        for key, value in pairs(defaultInventory) do
            if data[key] == nil then
                data[key] = value
            end
        end
        playerInventories[player.UserId] = data
    else
        -- If no data, use the default inventory
        playerInventories[player.UserId] = defaultInventory
    end

    -- Debugging: Ensure the inventory is loaded correctly
    printInventory(player)
    return playerInventories[player.UserId]
end

local function savePlayerInventory(player)
    local inventory = playerInventories[player.UserId]
    if inventory then
        print("Saving inventory for player:", player.Name, "Inventory:", inventory)
        local success, err = pcall(function()
            playerInventoryDataStore:SetAsync(player.UserId, inventory)
        end)
        if not success then
            warn("Failed to save inventory for player:", player.Name, "Error:", err)
        end
    else
        warn("No inventory to save for player:", player.Name)
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

local function addCoins(player, amount)
    local inventory = playerInventories[player.UserId]
    if inventory then
        -- Update the in-memory inventory
        inventory.coins = (inventory.coins or 0) + amount
        print(player.Name .. " earned " .. amount .. " coins. Total: " .. inventory.coins)

        -- Save the updated inventory
        local success, err = pcall(function()
            playerInventoryDataStore:SetAsync(player.UserId, inventory)
        end)
        if not success then
            warn("Failed to save inventory for player: " .. player.Name .. ". Error: " .. err)
        end

        -- Notify the client about the updated coin count
        addCoinsEvent:FireClient(player, amount)
    else
        warn("No inventory found for player: " .. player.Name)
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
            addCoins(player, 5)
            addCoinsEvent:FireClient(player, 5)
            savePlayerInventory(player)
        else
            print(player.Name .. " has already completed level: " .. levelName)
        end
    else
        warn("No inventory found for player: " .. player.Name)
    end
end

local function monitorMarble(player, character)
    -- Find the marble part in the character
    local marble = character:FindFirstChild("Marble") or character:FindFirstChildWhichIsA("BasePart")

    if not marble then
        warn("Marble or main part not found for player:", player.Name)
        return
    end

    print("Monitoring marble for player:", player.Name)

    -- Attach the Touched event to the marble
    marble.Touched:Connect(function(hit)
        if hit and hit:IsA("BasePart") then
            print("Touched part:", hit.Name)

            -- Check if the touched part is a hazard
            if string.find(hit.Name, "Hazard") then
                print(player.Name .. " touched a Hazard and will die.")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    deathSoundEvent:FireClient(player)
                    humanoid.Health = 0
                end
            elseif hit.Name == "HazardStatic" or hit.Name == "HazardRotate" then
                print(player.Name .. " touched a specific Hazard and will die.")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end

            elseif hit and hit:IsA("BasePart") and hit.Name:match("Level(%d+)Plate") then
            local levelNumber = tonumber(hit.Name:match("Level(%d+)"))
            if levelNumber then
                local levelName = "Level" .. levelNumber .. "Plate"
                completeLevel(player, levelName)
            end
        else
            end
        else
            print("Invalid part touched by:", player.Name)
        end
    end)
end



-- Handle the add coins request from the client
addCoinsEvent.OnServerEvent:Connect(function(player, amount)
    if typeof(amount) == "number" and amount > 0 then
        addCoins(player, amount)
    else
        warn("Invalid coin amount received from player: " .. player.Name)
    end
end)



game.Players.PlayerAdded:Connect(function(player)


    -- local success, err = pcall(function()
    --     playerInventoryDataStore:RemoveAsync(player.UserId)
    -- end)

    -- if success then
    --     print("Removed inventory for player:", player.Name)
    -- else
    --     warn("Failed to remove inventory for player:", player.Name, "Error:", err)
    -- end

    -- Load the player's inventory
    loadPlayerInventory(player)

    player.CharacterAdded:Connect(function(character)
        print(player.Name .. "'s character added.")

        -- Ensure the character is fully loaded
        local success, part = pcall(function()
            return character:WaitForChild("Marble", 10) -- Adjust timeout as needed
        end)

        if success and part then
            print(player.Name .. "'s character is ready for monitoring.")
            monitorMarble(player, character)
        else
            warn("Character failed to load properly for: " .. player.Name)
        end
    end)
end)

-- Add this to the server script
unlockMarbleEvent.OnServerEvent:Connect(function(player, marbleName)
    -- Validate input from the client
    if typeof(marbleName) == "string" then
        unlockMarble(player, marbleName)
    else
        warn("Invalid marble name received from player:", player.Name)
    end
end)


-- Save inventory when the player leaves
game.Players.PlayerRemoving:Connect(function(player)
    savePlayerInventory(player)
    playerInventories[player.UserId] = nil -- Remove from memory
end)


fetchInventoryFunction.OnServerInvoke = function(player)
    local inventory = playerInventories[player.UserId]
    if inventory then
        -- Print the inventory for debugging
        print("FetchInventoryFunction invoked for:", player.Name, "Inventory:", inventory)

        return {
            coins = inventory.coins or 0,
            beatenLevels = inventory.beatenLevels or {},
            unlockedMarbles = inventory.unlockedMarbles or {"DefaultMarble"},
        }
    else
        warn("No inventory found for player: " .. player.Name .. ". Returning default inventory.")
        return {
            coins = 0,
            beatenLevels = {},
            unlockedMarbles = {"DefaultMarble"},
        }
    end
end