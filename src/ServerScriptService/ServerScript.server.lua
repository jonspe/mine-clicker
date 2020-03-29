local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = require(script.Parent.DataStoreService)


local loadFunction = ReplicatedStorage.Load
local saveFunction = ReplicatedStorage.Save

loadFunction.OnServerInvoke = function(player)
	local worldStore = DataStoreService:GetDataStore("binary", tostring(player.UserId))
	
	local saveString
	local success, err = pcall(function()
		saveString = worldStore:GetAsync("chunk1")
	end)

	success = success and saveString ~= nil
	if not success then
		print("Could not load world!")
	end
	
	return success, saveString
end

saveFunction.OnServerInvoke = function(player, saveString)
	local worldStore = DataStoreService:GetDataStore("binary", tostring(player.UserId))
	local success, err = pcall(function()
		worldStore:SetAsync("chunk1", saveString)
	end)
	
	if not success then
		print("Could not save world!")
	end
	return success
end
