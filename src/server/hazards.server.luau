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
    end
end)
