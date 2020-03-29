local ROOT = script.Parent.Parent

local WorldData = require(ROOT.DataModules.WorldData)
local WorldConfig = require(ROOT.DataModules.WorldConfig)
local TerrainChunk = require(ROOT.TerrainDisplayModules.TerrainChunk)

local TILE_SIZE = WorldConfig.TILE_SIZE
local CHUNK_DIM = WorldConfig.CHUNK_DIM

local floor = math.floor

local TerrainDisplay = {}
local TerrainDisplay_mt = { __index = TerrainDisplay }

--[[**
	Creates a display for terrain with data used from WorldData. Handles
	drawing chunks, updating tiles and  transforming to terrain coordinates.
	
	@param [t:WorldData] worldData
	@param [t:Model] rootModel Where the chunks will be parented to
	@param [t:CFrame] transform Transformation matrix for all chunks & tiles
	@returns [t:TerrainDisplay]
**--]]
function TerrainDisplay.new(worldData, rootModel, transform)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = transform:GetComponents()
	local self = {
		worldData = worldData,
		rootModel = rootModel,
		transform = transform,
		invTransform = transform:inverse(),
		terrainChunks = {},
		
		_binaryChangedConnection = nil,
		_tileChangedConnection = nil,
	}
	
	setmetatable(self, TerrainDisplay_mt)
	
	self:initConnections()
	return self
end


function TerrainDisplay:initConnections()
	local function update(x, y)
		self:updateTile(x, y)
	end
	
	self._binaryChangedConnection = self.worldData.binaryChanged:Connect(update)
	self._tileChangedConnection = self.worldData.tileChanged:Connect(update)
end


function TerrainDisplay:clear()
	for _, chunk in pairs(self.terrainChunks) do
		chunk.model:Destroy()
	end
	self.terrainChunks = {}
end

--[[**
	Converts world coordinates to tile coordinates.
	
	@param [t:Vector3] worldPosition
	@returns [t:number] tileX
	@returns [t:number] tileY
**--]]
function TerrainDisplay:worldToTile(worldPosition)
	local tilePos = self.invTransform * worldPosition
	return floor(tilePos.x/TILE_SIZE), floor(-tilePos.y/TILE_SIZE)
end

--[[**
	Converts tile coordinates to world coordinates at tile center position.
	
	@param [t:number] tileX
	@param [t:number] tileY
	@returns [t:Vector3] worldPosition
**--]]
function TerrainDisplay:tileToWorld(tileX, tileY)
	local worldPos = self.transform * Vector3.new(TILE_SIZE * tileX, TILE_SIZE * tileY, 0)
	return worldPos
end

--[[**
	Draws a chunk in x, y chunk coordinates.
	
	@param [t:number] chunkX
	@param [t:number] chunkY
	@returns
**--]]
function TerrainDisplay:drawChunk(chunkX, chunkY)
	if chunkX < 0 or chunkX > WorldConfig.CHUNK_COL-1 or chunkY < 0 then
		return
	end
	
	self.worldData:loadChunk(chunkX, chunkY)
	local chunkIndex = WorldConfig.chunkXYtoIndex(chunkX, chunkY)
	
	local chunk = self.terrainChunks[chunkIndex]
	if chunk == nil then
		chunk = TerrainChunk.new(
			chunkIndex,
			self.worldData,
			self.transform * CFrame.new(
				CHUNK_DIM * TILE_SIZE * chunkX,
				-CHUNK_DIM * TILE_SIZE * chunkY,
				0),
			self.rootModel)
		
		self.terrainChunks[chunkIndex] = chunk
	end
	
	chunk:draw()
end

--[[**
	Hides a chunk in x, y chunk coordinates.
	
	@param [t:number] chunkX
	@param [t:number] chunkY
	@returns
**--]]
function TerrainDisplay:hideChunk(chunkX, chunkY)
	local chunkIndex = WorldConfig.chunkXYtoIndex(chunkX, chunkY)
	local chunk = self.terrainChunks[chunkIndex]
	
	if chunk ~= nil then
		chunk:hide()
	end
end

--[[**
	Redraws a single tile in x, y tile coordinates
	
	@param [t:number] tileX
	@param [t:number] tileY
	@returns
**--]]
function TerrainDisplay:updateTile(tileX, tileY)
	local chunkIndex = WorldConfig.tileXYtoChunkIndex(tileX, tileY)
	
	local chunk = self.terrainChunks[chunkIndex]
	if chunk ~= nil then
		chunk:updateTile(tileX % CHUNK_DIM, tileY % CHUNK_DIM)
	end
end


return TerrainDisplay
