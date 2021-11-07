local ROOT = script.Parent.Parent

local WorldData = require(ROOT.DataModules.WorldData)
local Chunk = require(ROOT.DataModules.Chunk)
local Block = require(ROOT.TerrainDisplayModules.Block)

local CHUNK_TILES = WorldData.CHUNK_TILES
local CHUNK_DIM = WorldData.CHUNK_DIM

local TerrainChunk = {}
TerrainChunk.__index = TerrainChunk

function TerrainChunk.new(tileChunk, binaryChunk, transform, rootModel)
	local self = {
		tileChunk = tileChunk,
		binaryChunk = binaryChunk,
		
		model = nil,
		rootModel = rootModel,
		transform = transform,
		
		blocks = {},
		
		isDrawn = false,
	}
	
	setmetatable(self, TerrainChunk)
	return self
end

function TerrainChunk:destroy()
	if self.model then
		self.model:Destroy()
	end
end

function TerrainChunk:calculateChunkBlocks()
	local blocks = {}
	local visited = Chunk.new(CHUNK_DIM, CHUNK_DIM, false)
	local block
	
	for x, y in self.tileChunk:horizontalIterator() do
		if not visited:get(x, y) then --hmm
			local id = self.tileChunk:get(x, y)
			local presence = self.binaryChunk:get(x, y)
			
			block = Block.new(
				self.model, self.transform,
				id, presence, x, x, y, y)
			
			local found_y = false
			
			for xx = x, CHUNK_DIM-1 do
				if visited:get(xx, y) or self.tileChunk:get(xx, y) ~= id
						or self.binaryChunk:get(xx, y) ~= presence then
					break
				end
				block.right = xx
				visited:set(xx, y, true)
			end
			
			
			for yy = y+1, CHUNK_DIM-1 do
				for xx = x, block.right do
					if visited:get(xx, yy) or self.tileChunk:get(xx, yy) ~= id
							or self.binaryChunk:get(xx, yy) ~= presence then
						block.bottom = yy-1
						found_y = true
						break
					end
					
				end
				if found_y then break end
				for xx = x, block.right do
					visited:set(xx, yy, true)
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
		self.model = Instance.new("Model")

		local tileSize = WorldData.TILE_SIZE
		
		local blocks = self:calculateChunkBlocks()
		self.blocks = blocks
		
		for _, block in ipairs(blocks) do
			block:draw()
		end
		
		self.isDrawn = true
		self.model.Parent = self.rootModel
	end
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
	local tileId = self.tileChunk:get(tileX, tileY)
	local presence = self.binaryChunk:get(tileX, tileY)

	local index, block = self:searchForBlock(tileX, tileY)
	local resultBlocks = block:poke(tileX, tileY, tileId, presence)
	
	table.remove(self.blocks, index)
	for _, block in pairs(resultBlocks) do
		table.insert(self.blocks, block)
		block:draw()
	end
end


return TerrainChunk