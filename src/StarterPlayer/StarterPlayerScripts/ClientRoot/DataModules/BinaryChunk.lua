local INT_BITS = 28

local BinaryChunk = {}
BinaryChunk.__index = BinaryChunk

-- data either table of integers or a bit (0 or 1)
function BinaryChunk.new(width, height, data)
    local widthInt = math.ceil(width/INT_BITS)
    local self = {
        width = width,
        widthInt = widthInt,
        height = height,

        data = typeof(data) == "table" and data or
                table.create(widthInt * height, data == 0 and 0 or 0xFFFFFFFF)
    }
    
    setmetatable(self, BinaryChunk)
    return self
end

function BinaryChunk:get(x, y)
    local index = y*self.widthInt + math.floor(x/INT_BITS) + 1
    local value = self.data[index]
    
    return value and bit32.extract(value, x % INT_BITS) == 0 or nil
end

function BinaryChunk:getInt(x, y)
    local index = y*self.widthInt + math.floor(x/INT_BITS) + 1
    return self.data[index]
end

function BinaryChunk:set(x, y, presence)
    local index = y*self.widthInt + math.floor(x/INT_BITS) + 1
    local value = self.data[index]
    local bit = presence and 0 or 1
    self.data[index] = bit32.replace(value, bit, x % INT_BITS)
end

function BinaryChunk:horizontalIterator()
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

function BinaryChunk:intIterator()
    local x = -1
    local y = 0
    return function()
        x = x + 1
        if x > self.widthInt - 1 then
            x = 0
            y = y + 1
        end

        if y < self.height then
            return self:getInt(x, y)
        end
    end
end


function BinaryChunk:verticalIterator()
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

return BinaryChunk