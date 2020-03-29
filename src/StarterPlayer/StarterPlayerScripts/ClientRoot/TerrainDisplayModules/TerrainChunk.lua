local ROOT = script.Parent.Parent

local WorldData = require(ROOT.DataModules.WorldData)
local WorldConfig = require(ROOT.DataModules.WorldConfig)
local Block = require(ROOT.TerrainDisplayModules.Block)

local CHUNK_TILES = WorldConfig.CHUNK_TILES
local CHUNK_DIM = WorldConfig.CHUNK_DIM

local TerrainChunk = {}
TerrainChunk.__index = TerrainChunk

function TerrainChunk.new(index, worldData, transform, rootModel)
	local x, y = WorldConfig.chunkIndexToXY(index)
	local self = {
		index = index,
		x = x,
		y = y,
		
		worldData = worldData,
		tileData = worldData.chunkTileData[index],
		binaryData = worldData.chunkBinaryData[index],
		
		model = Instance.new("Model"),
		rootModel = rootModel,
		transform = transform,
		
		blocks = {},
		
		isDrawn = false,
	}
	
	setmetatable(self, TerrainChunk)
	return self
end

function TerrainChunk:calculateChunkBlocks()
	local blocks = {}
	local visited = {}
	local block
	
	for index = 1, CHUNK_TILES do
		if not visited[index] then
			local x, y = WorldConfig.tileIndexToXY(index)
			
			local id = self.tileData[index]
			local bit = bit32.extract(self.binaryData[y+1], x)
			
			block = Block.new(
				self.model, self.transform,
				id, bit, x, x, y, y)
			
			local found_y = false
			
			for xx = x, CHUNK_DIM-1 do
				local index2 = WorldConfig.tileXYtoIndex(xx, y)
				if visited[index2] or self.tileData[index2] ~= id or bit32.extract(self.binaryData[y+1], xx) ~= bit then
					break
				end
				block.right = xx
				visited[index2] = true
			end
			
			
			for yy = y+1, CHUNK_DIM-1 do
				for xx = x, block.right do
					local index2 = WorldConfig.tileXYtoIndex(xx, yy)
					if visited[index2] or self.tileData[index2] ~= id or bit32.extract(self.binaryData[yy+1], xx) ~= bit then
						block.bottom = yy-1
						found_y = true
						break
					end
					
				end
				if found_y then break end
				for xx = x, block.right do
					local index2 = WorldConfig.tileXYtoIndex(xx, yy)
					visited[index2] = true
				end
				block.bottom = yy
			end
			
			table.insert(blocks, block)
		end
	end
	
	return blocks
end


function TerrainChunk:draw()
	if not self.isDrawn then
		local tileSize = WorldConfig.TILE_SIZE
		
		local blocks = self:calculateChunkBlocks()
		self.blocks = blocks
		
		for _, block in ipairs(blocks) do
			block:draw()
		end
		
		self.isDrawn = true
	end
	
	self.model.Parent = self.rootModel
end


function TerrainChunk:hide()
	self.model.Parent = nil
end

function TerrainChunk:searchForBlock(tileX, tileY)
	for index, block in ipairs(self.blocks) do
		if block.left <= tileX and block.right >= tileX
			and block.top <= tileY and block.bottom >= tileY then
			return index, block
		end
	end
	
	return nil --shouldn't happen
end


function TerrainChunk:updateTile(tileX, tileY)
	local tileIndex = WorldConfig.tileXYtoIndex(tileX, tileY)
	local bx, by = WorldConfig.tileXYtoBinaryXY(tileX, tileY)
	
	local tileId = self.tileData[tileIndex]
	local binary = bit32.extract(self.binaryData[by], bx)
	
	local index, block = self:searchForBlock(tileX, tileY)
	local resultBlocks = block:poke(tileX, tileY, tileId, binary)
	
	table.remove(self.blocks, index)
	for _, block in pairs(resultBlocks) do
		table.insert(self.blocks, block)
		block:draw()
	end
end


return TerrainChunk