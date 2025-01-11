-- Reference RunService for constant updates
local RunService = game:GetService("RunService")

-- Settings for spinning
local rotationSpeed = 45 -- Degrees per second

local function spinObject(object, deltaTime)
    print("haere")
    -- Debug: Check what object is passed
    if object then
        print("Object Name:", object.Name, "| Object Class:", object.ClassName)
    else
        warn("spinObject: Received a nil object")
        return
    end

    -- Ensure the object is a BasePart (covers Part, MeshPart, etc.)
    if object:IsA("BasePart") then
        print("Spinning:", object.Name)
        -- Calculate the rotation increment
        local increment = CFrame.Angles(0, math.rad(rotationSpeed * deltaTime), 0)
        object.CFrame = object.CFrame * increment
    else
        print("Object is not a BasePart:", object.Name, "| Type:", object.ClassName)
    end
end

-- Function to spin a part
local function spinObject(object, deltaTime)
    if object:IsA("BasePart") then
        -- Calculate the rotation increment
        local increment = CFrame.Angles(0, math.rad(45 * deltaTime), 0) -- Adjust rotation speed as needed
        object.CFrame = object.CFrame * increment
        -- print("Spinning:", object.Name)
    end
end

-- Function to spin a part
local function rotateObject(object, deltaTime)
    if object:IsA("BasePart") then
        -- Calculate the rotation increment
        local increment = CFrame.Angles(math.rad(45 * deltaTime), 0, 0) -- Adjust rotation speed as needed
        object.CFrame = object.CFrame * increment
        -- print("Spinning:", object.Name)
    end
end

-- Function to move a part up and down slightly
local function vibrateObject(object, deltaTime, amplitude, frequency)
    if object:IsA("BasePart") then
        -- Calculate the vertical offset using sine wave
        local offset = math.sin(tick() * frequency) * amplitude
        
        -- Adjust the object's position
        local position = object.Position
        object.Position = Vector3.new(position.X, position.Y + offset * deltaTime, position.Z)
    end
end

-- Connect to RunService.Stepped for smooth rotation
RunService.Stepped:Connect(function(_, deltaTime)
    -- Get all descendants in Workspace
    local descendants = workspace:GetDescendants()
    for _, descendant in ipairs(descendants) do
        -- Check if the object is named "Hazard" and is a BasePart
        if descendant.Name == "Hazard" and descendant:IsA("BasePart") then
            spinObject(descendant, deltaTime) -- Spin the hazard part
        end
        if descendant.Name == "SpinPart" and descendant:IsA("BasePart") then
            spinObject(descendant, deltaTime) -- Spin the hazard part
        end
        if descendant.Name == "SpinPartFaster" and descendant:IsA("BasePart") then
            spinObject(descendant, deltaTime*3) -- Spin the hazard part
        end
        if descendant.Name == "HazardRotate" and descendant:IsA("BasePart") then
            rotateObject(descendant, deltaTime) -- Spin the hazard part
        end
        if descendant.Name == "VibrateObj" and descendant:IsA("BasePart") then
            vibrateObject(descendant, 0.016, 10, 5)
        end
        if descendant.Name == "DropHazard" and descendant:IsA("BasePart") then
            vibrateObject(descendant, 0.016, 100, 2)
        end
        if descendant.Name == "SpinPartSlower" and descendant:IsA("BasePart") then
            spinObject(descendant, deltaTime*.4) -- Spin the hazard part
        end
    end
end)
