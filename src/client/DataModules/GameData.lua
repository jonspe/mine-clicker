local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadFunction = ReplicatedStorage.Load
local saveFunction = ReplicatedStorage.Save

local GameData = {}
GameData.__index = GameData

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

return GameData