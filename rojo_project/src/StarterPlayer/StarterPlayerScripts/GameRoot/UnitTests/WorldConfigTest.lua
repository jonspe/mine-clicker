local NexusUnitTesting = require("NexusUnitTesting")
local ROOT = script.Parent.Parent

return function()
	local WorldConfig = require(ROOT.DataModules.WorldConfig)
	
	describe("chunkIndexToXY",function()
		it("should calculate correct xy",function()
			local x, y = WorldConfig.chunkIndexToXY(4)
			expect(x).to.equal(3)
			expect(y).to.equal(0)
			
			x, y = WorldConfig.chunkIndexToXY(13)
			expect(x).to.equal(4)
			expect(y).to.equal(1)
			
			x, y = WorldConfig.chunkIndexToXY(54)
			expect(x).to.equal(5)
			expect(y).to.equal(6)
		end)
		
		it("should wrap around correctly in edge cases",function()
			local x, y = WorldConfig.chunkIndexToXY(8)
			expect(x).to.equal(7)
			expect(y).to.equal(0)
			
			x, y = WorldConfig.chunkIndexToXY(9)
			expect(x).to.equal(0)
			expect(y).to.equal(1)
			
			x, y = WorldConfig.chunkIndexToXY(64)
			expect(x).to.equal(7)
			expect(y).to.equal(7)
		end)
	end)
	
	describe("chunkXYtoIndex",function()
		it("should calculate correct index",function()
			expect(WorldConfig.chunkXYtoIndex(5,0)).to.equal(6)
			expect(WorldConfig.chunkXYtoIndex(1,1)).to.equal(10)
		end)
	end)
end