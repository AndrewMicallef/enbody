 require 'src.dependancies'

size = 800 -- size of the world block (true N is this value squared)
ox, oy = math.floor(size/2), math.floor(size/2)
onepx = 1/size
oneTU =  0.25


function copy_img_to_canvas(img, canvas)
	canvas:renderTo( function()
	   lg.setBlendMode("replace", "premultiplied")
	   lg.draw(lg.newImage(img))
	   lg.setBlendMode("alpha", "alphamultiply")
   end)
end

function duplicateCanvas(canvas)
    local newCanvas = love.graphics.newCanvas(canvas:getDimensions())
        newCanvas:renderTo(function()
            lg.setColor(1,1,1,1)
            lg.draw(canvas)
    end)
    return newCanvas
end

--[[
## LOGIC
	1. Sense
	2. Rotate
	3. Move
	4. Deposit
	5. Diffuse
	6. Decay
--]]

-- initiate textures
AgentTex = lg.newCanvas(size, size, {format='rgba32f'})
OrganismTex = lg.newCanvas(size, size, {format='rgba32f'})
FloorTex = lg.newCanvas(size, size, {format='rgba32f'})

-- load shaders
shader_sense = lg.newShader(love.filesystem.read('src/shaders/sense.glsl'))
shader_deposit = lg.newShader(love.filesystem.read('src/shaders/deposit.glsl'))
shader_difuse = lg.newShader(love.filesystem.read('src/shaders/difuse.glsl'))
shader_decay = lg.newShader(love.filesystem.read('src/shaders/decay.glsl'))

--spawn agents
AgentImg = love.image.newImageData(size, size, 'rgba32f')
OrganismImg = love.image.newImageData(size, size, 'rgba32f')
FloorImg = love.image.newImageData(size, size, 'rgba32f')

Buffer = lg.newCanvas(size, size, {format='rgba32f'})
Buffer:renderTo(function() lg.clear(0,0,0,1) end)

AgentBuf = duplicateCanvas(AgentTex)
FloorBuf = duplicateCanvas(FloorTex)

AgentImg:mapPixel(
	function(x,y,r,g,b,a)
		local i = y*size + x
		local angle = 2*math.pi * i/(size*size)
		local radius = onepx
		local heading = (love.math.random() * math.pi*2)%oneTU

		r = radius * math.cos(angle)
		g = radius * math.sin(angle)
		b = heading
		return r,g,b,1
	end
)

-- place
OrganismImg:mapPixel(
	function(x,y,r,g,b,a)
		if (x == ox) and (y == oy) then
			return 1,0,0,0
		else
			return 0,0,0,0
		end
	end
)

FloorImg:mapPixel(
	function(x,y,r,g,b,a)
		return 0,0,0,0
	end
)

copy_img_to_canvas(AgentImg, AgentTex)
copy_img_to_canvas(OrganismImg, OrganismTex)
copy_img_to_canvas(FloorImg, FloorTex)


function love.load()
end

function love.update(dt)
    lg.setCanvas()

    lg.setBlendMode("alpha", "premultiplied")

    -- sense
    Buffer:renderTo(function()
        lg.setColor(1,1,1,1)
        lg.setBlendMode("replace", "premultiplied")
        lg.setShader(shader_sense)
            shader_sense:send("uTime", love.timer.getTime())
            shader_sense:send("AgentTex", AgentTex)
            shader_sense:send("FloorTex", FloorTex)
            shader_sense:send("dt", dt)
            lg.draw(AgentBuf)
        lg.setShader()
    end)
    AgentTex:renderTo(function()
        lg.setBlendMode("replace", "premultiplied")
        lg.draw(Buffer)
    end)
    AgentBuf:renderTo(function()
        lg.setBlendMode("replace", "premultiplied")
        lg.draw(AgentTex)
    end)


    -- deposit
    Buffer:renderTo(function()
        lg.clear(0,0,0,0)
        lg.setBlendMode("add", "premultiplied")
        lg.setShader(shader_deposit)
            shader_deposit:send("AgentTex", AgentTex)
            shader_deposit:send("FloorTex", FloorTex)
            lg.draw(FloorBuf)
        lg.setShader()
    end)
    FloorTex:renderTo(function()
        lg.setBlendMode("replace", "premultiplied")
        lg.draw(Buffer)
    end)
    FloorBuf:renderTo(function()
        lg.setBlendMode("replace", "premultiplied")
        lg.draw(FloorTex)
    end)



	-- set shader: deposit
	-- set canvas: FloorTex
	-- draw()
	-- set shader: diffuse
	-- set canvas: FloorTex
	-- draw()
	-- set shader: decay
	-- set canvas: FloorTex
	-- draw()

	-- render FloorTex to screen...

end

function love.draw()

	local sw, sh = lg.getDimensions()

    lg.setColor(1,1,1, 1.0)
    lg.setBlendMode("none", "alphamultiply")
    lg.setShader()
    lg.draw(FloorTex)



	-- draw Information
    lg.setShader()
	lg.setColor(1,1,1, 1.0)
	lg.setBlendMode("alpha", "alphamultiply")
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
