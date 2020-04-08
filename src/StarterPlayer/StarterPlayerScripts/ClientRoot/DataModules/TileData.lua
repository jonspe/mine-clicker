local TileData = {}
local data = nil

function TileData.loadData(tileset)
	data = {}
	for t = 1, #tileset, 4 do
		local index = 1 + math.floor((t-1)/4)
		data[index] =
		{
			id = index,

			name = tileset[t],
			toughness = tileset[t+1],
			value = tileset[t+2],

			texture = "rbxassetid://" .. tileset[t+3]
		}
	end
end

function TileData.getTile(id)
	return data[id]
end

return TileData