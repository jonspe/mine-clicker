local NexusUnitTesting = require("NexusUnitTesting")
local ROOT = script.Parent.Parent

return function()
	local WorldData = require(ROOT.DataModules.WorldData)
	local TerrainDisplay = require(ROOT.TerrainDisplayModules.TerrainDisplay)
	local TerrainGenerator = require(ROOT.TerrainGenerationModules.TerrainGenerator)
	
	describe("tileToWorld",function()
		
		local transform = CFrame.new(
			0, 5, 4,
			4, 0, 0,
			0, -4, 0,
			0, 0, -4)
		
		local terrainGen = TerrainGenerator.new(0)
		local worldData = WorldData.new()
		local terrain = TerrainDisplay.new(worldData, nil, transform)
		
		it("should convert tile coords to world position",function()
			local position = terrain:tileToWorld(0, 0)
			expect(position).to.equal(Vector3.new(0, 5, 4))
			
			position = terrain:tileToWorld(6, 8)
			expect(position).to.equal(Vector3.new(24, -27, 4))
			
			position = terrain:tileToWorld(-10, 5)
			expect(position).to.equal(Vector3.new(-40, -15, 4))
		end)
			
		it("should convert world position to tile coords",function()
			local x, y = terrain:worldToTile(Vector3.new(0, 0, 4))
			expect(x).to.equal(0)
			expect(y).to.equal(-2)
			
			x, y = terrain:worldToTile(Vector3.new(8, 12, 4))
			expect(x).to.equal(2)
			expect(y).to.equal(-5)
			
			x, y = terrain:worldToTile(Vector3.new(10, -22, 4))
			expect(x).to.equal(2)
			expect(y).to.equal(7)
		end)
	end)

end