local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ROOT = script.Parent

local TerrainGenerator = require(ROOT.TerrainGenerationModules.TerrainGenerator)
local ImageLayer = require(ROOT.TerrainGenerationModules.ImageLayer)
local DrawFunctions = require(ROOT.TerrainGenerationModules.DrawFunctions)
local FilterFunctions = require(ROOT.TerrainGenerationModules.FilterFunctions)
local SedimentLayers = require(ROOT.TerrainGenerationModules.SedimentLayers)
local WorldData = require(ROOT.DataModules.WorldData)
local TerrainDisplay = require(ROOT.TerrainDisplayModules.TerrainDisplay)
local Timer = require(ROOT.HelperModules.Timer).new()

local SEDIMENT_DATA = require(ROOT.DataModules.SedimentData1)
local sedimentLayers = SedimentLayers.new(SEDIMENT_DATA)

local Remotes = ReplicatedStorage.Remotes


local seed = math.random(-10000, 10000)
local terrainGen = TerrainGenerator.new(seed) do
	local draw = DrawFunctions
	local filter = FilterFunctions

	local sediments = ImageLayer.new() do -- ore gen is SLOW and a BOTTLENECK
		sediments:draw("MIX", 	1,		draw.noise(.05, .05, 0, 0))
		sediments:draw("MIX", 	0.5,	draw.noise(.1, .1, 0, 0)) --increasing perlin noise depth, more detailed
		sediments:draw("MIX", 	0.25,	draw.noise(.2, .2, 0, 0))
		sediments:draw("MIX", 	0.125,	draw.noise(.4, .4, 0, 0))
		sediments:draw("MIX", 	0.92,	draw.constant(.5)) --reduce contrast to emphasize gradient overlay, makes more "stepped" sediment

		sediments:draw("OVERLAY",	1,	draw.gradient(0, 0, 0, sedimentLayers.cumulativeDepth))
		sediments:filter("MIX",		1,	filter.step(sedimentLayers.sedimentThresholdData))

		local commonOreMask = ImageLayer.new()
		commonOreMask:draw("MIX", 		1,		draw.noise(.3, .3, 100, 0))
		commonOreMask:draw("MIX", 		0.5,	draw.noise(.6, .6, 100, 0))
		commonOreMask:draw("MASK",		1,		draw.constant(.6))
		
		local rareOreMask = ImageLayer.new()
		rareOreMask:draw("MIX", 		1,		draw.noise(.2, .2, 20, 0))
		rareOreMask:draw("MIX", 		0.5,	draw.noise(.4, .4, 20, 0))
		rareOreMask:draw("MASK",		1,		draw.constant(.675))
		
		local preciousOreMask = ImageLayer.new()
		preciousOreMask:draw("MIX", 	1,		draw.noise(.15, .15, 50, 0))
		preciousOreMask:draw("MIX", 	0.5,	draw.noise(.3, .3, 50, 0))
		preciousOreMask:draw("MASK",	1,		draw.constant(.69))
		
		local oreMask = ImageLayer.new()
		oreMask:mix("ALPHA_MIX",		0.25,	commonOreMask)
		oreMask:mix("ALPHA_MIX",		0.5,	rareOreMask)
		oreMask:mix("ALPHA_MIX",		0.75,	preciousOreMask)
		
		sediments:mix("ADD",			1/sedimentLayers.layerCount,	oreMask)
	end

	local ground = ImageLayer.new() do
		ground:draw("MIX", 	1, 	draw.gradient(0, 0, 0, 15))
		ground:draw("OVERLAY",	1, 	draw.noise(.07, .07, 0, 0))
	end

	terrainGen:setSurface(ground, {0, 0.3, 0.4, 0.6}, {0, 1, 2, -1})
	terrainGen:setSediments(sediments, sedimentLayers.tileThresholdData, sedimentLayers.tileData)
end



local LoadWorld = Remotes.LoadWorld
local SaveWorld = Remotes.SaveWorld


local rootModel = Instance.new("Model")
rootModel.Parent = workspace

local world = WorldData.new(terrainGen)
local terrain = TerrainDisplay.new(world, rootModel, CFrame.new(
		-WorldData.CHUNK_COL*WorldData.CHUNK_DIM*WorldData.TILE_SIZE/2, 50, 0))



local abs = math.abs
local function planeIntersection(ray, planeTransform)
	local normal = planeTransform.LookVector
	local point = planeTransform.p
	local denom = normal:Dot(ray.Direction)
	
	if abs(denom) >= 1e-6 then
		local x = (normal:Dot(point) - normal:Dot(ray.Origin)) / denom
		if x < 0 then
			return false
		end
		
		return true, ray.Origin + ray.Direction*x
	end
	
	return false
end



local mouse = game.Players.LocalPlayer:GetMouse()
local function mineBlock()
	local ray = mouse.UnitRay
	local hit, contact = planeIntersection(ray, terrain.transform * CFrame.new(0, 0, WorldData.TILE_SIZE/2))
	if hit then
		local x, y = terrain:worldToTile(contact)
		world:setPresence(x, y, false)
	end
end

local mouseDown = false
mouse.Button1Down:Connect(function()
	mouseDown = true
	mineBlock()
end)
mouse.Button1Up:Connect(function()
	mouseDown = false
end)

mouse.Move:Connect(function()
	if mouseDown then
		mineBlock()
	end
end)

local lastPos = Vector3.new()

game.Players.LocalPlayer.CharacterAdded:Connect(function()
	local hrp = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
	
	while true do
		wait(.1)
		local pos = hrp.Position
		local x, y = terrain:worldToTile(pos)
		local cx, cy = WorldData.tileToChunkCoordinates(x, y)
		
		for xx = -1, 1 do
			for yy = -1, 1 do
				terrain:drawChunk(cx+xx, cy+yy)
			end
		end
		
		--print(string.format("%s, %s", x, y))
	end
end)

UserInputService.InputBegan:Connect(function(inputObject)
	if inputObject.KeyCode == Enum.KeyCode.B then
		
		local saveString = world:binaryDataToString()
		local success = SaveWorld:InvokeServer(saveString)
		
		if success then
			print("saved")
		else
			print("wut")
		end
		
	elseif inputObject.KeyCode == Enum.KeyCode.N then
		
		local success, loadString = LoadWorld:InvokeServer()
		if success then
			terrain:clear()
			world:loadBinaryDataString(loadString)
			print("loaded!")
		else
			print("wutll")
		end
	end
end)
