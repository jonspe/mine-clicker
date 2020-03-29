local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ROOT = script.Parent

local TerrainGenerator = require(ROOT.TerrainGenerationModules.TerrainGenerator)
local ImageProcessor = require(ROOT.TerrainGenerationModules.ImageProcessor)
local DrawFunctions = require(ROOT.TerrainGenerationModules.DrawFunctions)
local SedimentLayers = require(ROOT.TerrainGenerationModules.SedimentLayers)
local WorldData = require(ROOT.DataModules.WorldData)
local WorldConfig = require(ROOT.DataModules.WorldConfig)
local TerrainDisplay = require(ROOT.TerrainDisplayModules.TerrainDisplay)
local Timer = require(ROOT.HelperModules.Timer).new()

local SEDIMENT_DATA = require(ROOT.DataModules.SedimentDataSets.SedimentData1)



local loadFunction = ReplicatedStorage.Load
local saveFunction = ReplicatedStorage.Save


local sedimentLayers = SedimentLayers.new()
sedimentLayers:processData(SEDIMENT_DATA)


local seed = 0--math.random(-10000, 10000)
local terrainGen = TerrainGenerator.new(
	seed,
	sedimentLayers.thresholdData,
	sedimentLayers.tileData) do
	
	local draw = DrawFunctions
	
	local sediments = ImageProcessor.new()
	sediments:blend("MIX", 	1,		draw.noise(.05, .05, 0, 0))
	sediments:blend("MIX", 	0.5,	draw.noise(.1, .1, 0, 0)) --increasing perlin noise depth, more detailed
	sediments:blend("MIX", 	0.25,	draw.noise(.2, .2, 0, 0))
	sediments:blend("MIX", 	0.125,	draw.noise(.4, .4, 0, 0))
	sediments:blend("MIX", 	0.83,	draw.constant(.5)) --reduce contrast to emphasize gradient overlay, makes more "stepped" sediment
	
	--sediments:blend("ADD",	
	sediments:blend("OVERLAY",		1,	draw.gradient(0, 0, 0, sedimentLayers.cumulativeDepth))
	
	terrainGen:addImageProcessor(sediments)
	
	--[[
	local ground = ThresholdDrawer.new({0, 0.25, 0.285, 0.38}, {0, 1, 2, 3})
	ground:blend("ADD", 	1, 	draw.gradient(0, 0, 0, 40))
	ground:blend("OVERLAY",	1, 	draw.noise(.055, .055, 0, 0))
	terrainGen:addDrawer(ground)
	]]
	
	
	
end

local rootModel = Instance.new("Model")
rootModel.Parent = workspace

local world = WorldData.new(terrainGen)
local terrain = TerrainDisplay.new(
	world,
	rootModel,
	CFrame.new(-WorldConfig.CHUNK_COL*WorldConfig.CHUNK_DIM*WorldConfig.TILE_SIZE/2, 50, 0))


--[[
Timer:tick("gen")
for y = 0, 31 do
	for x = 0, 15 do
		terrain:drawChunk(x, y)
	end
end
Timer:tock()
]]





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
	local hit, contact = planeIntersection(ray, terrain.transform * CFrame.new(0, 0, WorldConfig.TILE_SIZE/2))
	if hit then
		local x, y = terrain:worldToTile(contact)
		--print(x, y)
		world:setBinary(x, y, 1)
		--world:setTile(x, y, 3)
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
	local torch_emitter = game.ReplicatedStorage.Lights.TorchEmitter
	torch_emitter.Light:Clone().Parent = hrp
	while true do
		wait(.1)
		local pos = hrp.Position
		local x, y = terrain:worldToTile(pos)
		local cx, cy = WorldConfig.tileXYtoChunkXY(x, y)
		
		for xx = -1, 1 do
			for yy = -1, 1 do
				terrain:drawChunk(cx+xx, cy+yy)
			end
		end
		
		if (lastPos - pos).magnitude > 15 then
			lastPos = pos
			local t = torch_emitter:Clone()
			t.CFrame = CFrame.new(pos)
			t.Parent = workspace
		end
		print(string.format("%s, %s", x, y))
	end
end)




UserInputService.InputBegan:Connect(function(inputObject)
	if inputObject.KeyCode == Enum.KeyCode.B then
		
		local saveString = world:binaryDataToString()
		local success = saveFunction:InvokeServer(saveString)
		
		if success then
			print("saved")
		else
			print("wut")
		end
		
	elseif inputObject.KeyCode == Enum.KeyCode.N then
		
		local success, loadString = loadFunction:InvokeServer()
		if success then
			terrain:clear()
			world:loadBinaryData(loadString)
			print("loaded!")
		else
			print("wutll")
		end
	end
end)

local sky_emitter = game.ReplicatedStorage.Lights.SkyEmitter
local torch_emitter = game.ReplicatedStorage.Lights.TorchEmitter

local width = WorldConfig.MAP_X * WorldConfig.TILE_SIZE
sky_emitter.CFrame = terrain.transform * CFrame.new(width/2, -12, 8)
sky_emitter.Size = Vector3.new(width, 4, 24)
sky_emitter.Parent = workspace

--game.Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
--game.Lighting.Brightness = 0




--[[ DATA STORE DEMO
	
world:initZeroBinaryData()
local save_string = world:binaryDataToString()
local world_store = DataStoreService:GetDataStore("world_data", tostring(35434))

Timer:tick()
world_store:SetAsync("binary", save_string)
Timer:tock()

Timer:tick()
local retrieved_data
local success, err = pcall(function()
	retrieved_data = world_store:GetAsync("binary")
end)
Timer:tock()
if success then
	print("success")
	
	Timer:tick()
	world:loadBinaryData(retrieved_data)
	Timer:tock()
	
	local same_string = world:binaryDataToString()
	print(#save_string)
	print(#same_string)
	print(same_string == save_string)
end

]]

