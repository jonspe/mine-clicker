local ROOT = script.Parent.Parent
local perlinNoise = require(ROOT.TerrainGenerationModules.Noise)


local abs = math.abs
local clamp = math.clamp
local sqrt = math.sqrt

local function lerp(a, b, t)
	return a + t*(b - a);
end



local function noise(sx, sy, ox, oy) --sx = scale x, ox = offset x
	return function(x, y, seed)
		return perlinNoise((x-ox+seed)*sx, (y-oy)*sy, 0)
	end
end

local function ball(ox, oy, r, t, inv) --t = sharpness threshold
	return function(x, y)
		local dist = sqrt((x-ox)*(x-ox) + (y-oy)*(y-oy))
		return lerp(1-inv, inv, clamp((dist/r-t)/(1-t), 0, 1))
	end
end

local function constant(v)
	return function()
		return v
	end
end

--https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
--x0y0 black start, x1y1 white start
local function gradient(x0, y0, x1, y1)
	local cx, cy = (x0+x1)/2, (y0+y1)/2 --middle point
	local dist = sqrt((x1-x0)*(x1-x0) + (y1-y0)*(y1-y0))
	local x2, y2 = cy - y0 + cx, x0 - cx + cy --rotate 90 deg around middle to get line along gradient
	local x3, y3 = cy - y1 + cx, x1 - cx + cy
	local xx, yy = x3-x2, y3-y2 --optimization
	local x3y2, y3x2 = x3*y2, y3*x2 --optimization
	local sqxxyy = sqrt(xx*xx + yy*yy) --optimization
	
	return function(x, y)
		local dline = (yy*x - xx*y + x3y2 - y3x2) / sqxxyy --wikipedia, dist from point to line
		return clamp(.5+dline/dist, 0, 1)
	end
end


return {
	noise = noise,
	ball = ball,
	constant = constant,
	gradient = gradient,
}
