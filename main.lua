lg = love.graphics

--lg.setDefaultFilter("nearest", "nearest")
lg.setPointSize(5)

size = 800 -- size of the world block (true N is this value squared)
ox, oy = math.floor(size/2), math.floor(size/2)
onepx = 1/size -- size of one pixel
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

-- load shaders
shader_sense = lg.newShader(love.filesystem.read('src/shaders/sense.glsl'))
shader_deposit = lg.newShader(love.filesystem.read('src/shaders/deposit.glsl'))
shader_difuse = lg.newShader(love.filesystem.read('src/shaders/difuse.glsl'))
shader_decay = lg.newShader(love.filesystem.read('src/shaders/decay.glsl'))


Buffer = lg.newCanvas(size, size, {format='rgba32f'})
Buffer:renderTo(function() lg.clear(0,0,0,1) end)

-- initiate textures
AgentTex = lg.newCanvas(size, size, {format='rgba32f'})
AgentImg = love.image.newImageData(size, size, 'rgba32f')
AgentBuf = duplicateCanvas(AgentTex)

--spawn agents in a circle
AgentImg:mapPixel(
	function(x,y,r,g,b,a)
		local i = y*size + x
		local angle = 2*math.pi * i/(size*size)
		local radius = size*.2
		local heading = (love.math.random() * math.pi*2)%oneTU

		r = radius * math.cos(angle)
		g = radius * math.sin(angle)
		b = heading
		return r+size/2,g+size/2,b,1
	end
)

copy_img_to_canvas(AgentImg, AgentTex)

FloorTex = lg.newCanvas(size, size, {format='rgba32f'})
FloorImg = love.image.newImageData(size, size, 'rgba32f')
FloorBuf = duplicateCanvas(FloorTex)

--construct vertex table
points = {}
for u = 1, size do
    for v = 1, size do
        table.insert(points, {
            (u) / size,
            (v) / size,
        })
    end
end

FloorMesh = lg.newMesh(points, "points", "static")




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

	-- deposit
	FloorTex:renderTo(function()
		lg.push(all)
		--lg.clear(0,0,0,1)
		lg.setColor(1,1,1,1)
		lg.setBlendMode("add", "premultiplied")
		lg.setShader(shader_deposit)
		shader_deposit:send("AgentTex", AgentTex)
		lg.draw(FloorMesh)
		lg.pop(all)
	end)

	-- diffuse
	Buffer:renderTo(function()
		lg.push(all)
		lg.clear(0,0,0,0) -- clear the buffer to begin
		lg.setColor(1,1,1,1)
		lg.setBlendMode("replace", "premultiplied")
		lg.setShader(shader_difuse)
		shader_difuse:send("FloorTex", FloorTex)
		lg.draw(FloorTex)
		lg.pop(all)
	end)
	FloorTex:renderTo(function()
		lg.clear(0,0,0,0) -- clear the buffer to begin
		lg.setColor(1,1,1,1)
		lg.setBlendMode("replace", "premultiplied")
		lg.draw(Buffer)
	end)

	-- decay
	Buffer:renderTo(function()
        lg.push(all)
		lg.clear(0,0,0,0) -- clear the buffer to begin
		lg.setColor(1,1,1,1)
        lg.setBlendMode("replace", "premultiplied")
        lg.setShader(shader_decay)
        shader_decay:send("FloorTex", FloorTex)
		shader_decay:send("dt", dt)
        lg.draw(FloorTex)
        lg.pop(all)
    end)
	FloorTex:renderTo(function()
		lg.setBlendMode("replace", "premultiplied")
		lg.draw(Buffer)
	end)

	-- render FloorTex to screen...

end

function love.draw()

	local sw, sh = lg.getDimensions()

    lg.setColor(1,1,1,1)
	lg.clear(0,0,0,1)
    lg.setBlendMode("none", "premultiplied")
    lg.setCanvas()
    lg.setShader()
    lg.draw(FloorTex)

	-- draw Information
    lg.setShader()
	lg.setColor(1,1,1, 1.0)
	lg.setBlendMode("alpha", "alphamultiply")
	lg.printf("PHSYARUM", 0, 10, sw, "center")
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
