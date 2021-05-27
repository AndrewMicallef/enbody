require 'src.dependancies'

N2_part = 10
N2_worldsize = 150

-- setup buffers:

agents = {}
world = {}

for k, t in pairs{
	--agent buffers
	pos = {N2_part, "rgba32f"},
	heading = {N2_part, "rgba32f"},

	-- TODO sensors
	sensor = {N2_part, "rgba8"}, -- 3 sensors per particle [xyz] + distance [w]
	} do
	local dim, fmt = t[1], t[2]
	agents[k] = lg.newCanvas(dim, dim, {format=fmt})
	print("constructed agent data: "..k)
end

for k, t in pairs{
	-- pheromone trial
	trial = {N2_worldsize, "rgba8"},

	-- obstacles
	-- walls = {},
	} do
	local dim, fmt = t[1], t[2]
	world[k] = lg.newCanvas(dim, dim, {format=fmt})
	print("constructed world dat: "..k)
end


--[[
## LOGIC
	1. Sense
	-- Check each sensor for presense of trial
	-- if front sensor  and not sides has trail
		 	no rotation
	   if front sensor and left sensor,
	   		rotate right slightly
	   if front sensor and right sensor,
	 	   		rotate left slightly

	   if no sensor

	--
	2. Rotate
	3. Move
	4. Deposit
	5. Diffuse
	6. Decay
--]]

--




function love.load()

	--particles = Particles{ntypes=5, dim=64}

end

function love.update(dt)
	--particles:update(dt)
end

function love.draw()

	local sw, sh = lg.getDimensions()

	--particles:render()

	-- draw Information
	lg.setColor(1,1,1, 1.0)
	lg.printf("ENBODY:\nPhysarum", 0, 10, sw, "center")
	for i,v in ipairs {
		{"Q / ESC", "quit"},
		{"R", "reset"},
	} do
		local y = sh - (16 * i + 10)
		lg.printf(v[1], 0, y, sw * 0.5 - 10, "right")
		lg.printf(v[2], sw * 0.5 + 10, y, sw * 0.5 - 10, "left")
		lg.printf("-", sw * 0.5 - 10, y, 20, "center")
	end
	lg.setColor(1,1,1,1)

end


--respond to input
function love.keypressed(k)
	--new world
	if k == "r" then
		--restart, soft or hard
		if love.keyboard.isDown("lctrl") then
			love.event.quit("restart")
		else
			love.load()
		end
	--quit
	elseif k == "q" or k == "escape" then
		--quit out
		love.event.quit()
	end
end
