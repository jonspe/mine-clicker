local BinaryChunk = {}
BinaryChunk.__index = BinaryChunk

function BinaryChunk.new(width, height, bit)
    local widthInt = math.ceil(width/32)
    local self = {
        width = width,
        widthInt = widthInt,
        height = height,

        data = table.create(widthInt * height, bit == 0 and 0 or 0xFFFFFFFF)
    }
    
    setmetatable(self, BinaryChunk)
    return self
end

function BinaryChunk:get(x, y)
    local index = y*self.widthInt + math.floor(x/32)
    local value = self.data[index]

    return bit32.extract(value, x % 32)
end

function BinaryChunk:set(x, y, bit)
    local index = y*self.widthInt + math.floor(x/32)
    local value = self.data[index]

    self.data[index] = bit32.replace(value, bit, x % 32)
end

return BinaryChunk