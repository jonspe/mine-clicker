local Chunk = {}
Chunk.__index = Chunk

function Chunk.new(width, height, value)
    local self = {
        width = width,
        height = height,

        data = table.create(width * height, value)
    }
    
    setmetatable(self, Chunk)
    return self
end

function Chunk:get(x, y)
    local index = y*self.width + x + 1
    return self.data[index]
end

function Chunk:set(x, y, value)
    local index = y*self.width + x + 1
    self.data[index] = value
end

return Chunk