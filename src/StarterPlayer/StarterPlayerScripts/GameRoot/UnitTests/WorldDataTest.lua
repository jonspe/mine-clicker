local ROOT = script.Parent.Parent
local NexusUnitTesting = require("NexusUnitTesting")

return function()
	local WorldConfig = require(ROOT.DataModules.WorldConfig)
	
	local WorldData = require(ROOT.DataModules.WorldData)
	local TerrainGenerator = require(ROOT.TerrainGenerationModules.TerrainGenerator)
	
	describe("SetBitTest",function()
		it("should set bits correctly in first binary chunk",function()
			local data = WorldData.new()
			
			data:setBinary(7, 2, 1)
			data:setBinary(8, 2, 1)
			data:setBinary(3, 3, 0)

			expect(data:getBinary(7, 2)).to.equal(1)
			expect(data:getBinary(8, 2)).to.equal(1)
			expect(data:getBinary(3, 3)).to.equal(0)
		end)
			
		it("should set bits correctly in other binary chunks",function()
			local data = WorldData.new()
			
			data:setBinary(7, 2, 1)
			data:setBinary(46, 88, 1)
			data:setBinary(200, 400, 0)
			data:setBinary(200, 401, 1)
			data:setBinary(220, 405, 0)

			expect(data:getBinary(7, 2)).to.equal(1)
			expect(data:getBinary(46, 88)).to.equal(1)
			expect(data:getBinary(200, 400)).to.equal(0)
			expect(data:getBinary(200, 401)).to.equal(1)
			expect(data:getBinary(220, 405)).to.equal(0)
		end)
	end)
		
	describe("ChunkIteratorTest",function()
		it("should get correct values at start",function()
			local terraingen = TerrainGenerator.new()
			local data = WorldData.new(terraingen)
			data:setTile(0, 0, 4)
			data:setTile(1, 0, 2)
			data:setTile(2, 0, 3)
			
			local it = data:chunk_iterator(1)
			
			local tileId, binary, x, y, index = it()
			expect(tileId).to.equal(4)
			expect(x).to.equal(0)
			expect(y).to.equal(0)
			expect(index).to.equal(1)
			
			tileId, binary, x, y, index = it()
			expect(tileId).to.equal(2)
			expect(x).to.equal(1)
			expect(y).to.equal(0)
			expect(index).to.equal(2)
			
			tileId, binary, x, y, index = it()
			expect(tileId).to.equal(3)
			expect(x).to.equal(2)
			expect(y).to.equal(0)
			expect(index).to.equal(3)
		end)
	end)
end