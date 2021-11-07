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

function Chunk:horizontalIterator()
    local x = -1
    local y = 0
    return function()
        x = x + 1
        if x > self.width - 1 then
            x = 0
            y = y + 1
        end

        if y < self.height then
            return x, y, self:get(x, y)
        end
    end
end

function Chunk:verticalIterator()
    local x = 0
    local y = -1
    return function()
        y = y + 1
        if y > self.height - 1 then
            y = 0
            x = x + 1
        end

        if x < self.width then
            return x, y, self:get(x, y)
        end
    end
end

return Chunk