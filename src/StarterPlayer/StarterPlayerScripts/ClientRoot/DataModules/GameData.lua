local HttpService = game:GetService("HttpService")

local loadFunction = ReplicatedStorage.Load
local saveFunction = ReplicatedStorage.Save


local GameData = {}
local GameData.__index = GameData

function GameData.new()
    local self = {
        money = 0,

        workers = {},
    }
    
    setmetatable(self, GameData)
    return self
end

function GameData:load()
    --local dataString =
    --local data = HttpService:JSONDecode(dataString)

end

function GameData:load()
    
end

return GameData