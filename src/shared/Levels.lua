local Levels = {}

for i = 1, 20 do
    table.insert(Levels, {
        Name = "Level " .. i,
        Description = "This is the description for Level " .. i .. ".",
        Location = "Level" .. i .. "Plate", -- Dynamically add the location
    })
end

return Levels
