local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ROOT = script.Parent.Parent
local WorldData = require(ROOT.DataModules.WorldData)
local TileData = require(ROOT.DataModules.TileData)

local TILE_SIZE = WorldData.TILE_SIZE

local TileTemplate = ReplicatedStorage.Common.Tile


local Block = {}
Block.__index = Block

function Block.new(rootModel, transform, tileId, presence, left, right, top, bottom)
	local self = {
		tileId = tileId,
		presence = presence,
		
		left = left,
		right = right,
		top = top,
		bottom = bottom,
		
		rootModel = rootModel,
		transform = transform,
		part = nil
	}
	
	setmetatable(self, Block)
	return self
end

function Block:draw()
	if self.part then
		self.part:Destroy()
	end
	
	if self.tileId > 0 then
		local width = self.right - self.left + 1
		local height = self.bottom - self.top + 1
		
		local offset = self.presence and 0 or 1

		local part = TileTemplate:Clone()
		part.Size = TILE_SIZE * Vector3.new(width, height, 1)
		part.Texture.Texture = TileData.getTile(self.tileId).texture
		part.Texture.Color3 = Color3.new(1-offset*.3, 1-offset*.3, 1-offset*.3)
		--part.Texture.OffsetStudsU = TILE_SIZE/2 * (width % 2)
		--part.Texture.OffsetStudsV = TILE_SIZE/2 * (height % 2)
		part.Texture.StudsPerTileU = TILE_SIZE
		part.Texture.StudsPerTileV = TILE_SIZE
		
		part.CFrame = self.transform
						* CFrame.new(TILE_SIZE * Vector3.new(self.left + width/2, -(self.top + height/2), -offset))
						* CFrame.Angles(0, math.pi, 0)
		part.Parent = self.rootModel
		
		self.part = part
	end
end


function Block:poke(x, y, tileId, presence)
	if x < self.left or x > self.right or y < self.top or y > self.bottom then
		error("poking the wrong hole!")
	end
	
	if tileId == self.tileId and presence == self.presence then
		-- do nothing
		return {self}
	end
	
	if self.part then
		self.part:Destroy()
	end
	
	local newBlock = Block.new(self.rootModel, self.transform, tileId, presence, x, x, y, y)
	local topBlock, bottomBlock, leftBlock, rightBlock
	
	if x > self.left then
		leftBlock = Block.new(
			self.rootModel, self.transform,
			self.tileId, self.presence,
			self.left, x-1, self.top, self.bottom)
	end
	if x < self.right then
		rightBlock = Block.new(
			self.rootModel, self.transform,
			self.tileId, self.presence,
			x+1, self.right, self.top, self.bottom)
	end
	
	if y > self.top then
		topBlock = Block.new(
			self.rootModel, self.transform,
			self.tileId, self.presence,
			x, x, self.top, y-1)
	end
	if y < self.bottom then
		bottomBlock = Block.new(
			self.rootModel, self.transform,
			self.tileId, self.presence,
			x, x, y+1, self.bottom)
	end
	
	local blocks = {}
	table.insert(blocks, newBlock)
	table.insert(blocks, leftBlock)
	table.insert(blocks, rightBlock)
	table.insert(blocks, topBlock)
	table.insert(blocks, bottomBlock)
	
	-- REMOVE BIG BLOCK IF NEEDED
	-- DRAW RESULT BLOCKS AND RETURN THEM
	
	return blocks
end

return Block