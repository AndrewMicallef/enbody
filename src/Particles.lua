Particles = class()

lg.setPointSize(2)

local args_defaults = {
    --dimension of the particles textures
    dim = 64,

    --number of discrete particle types
    ntypes = 5,

    -- type of spawn distribution
    gen = 'base',

    --amount to downres the render buffer
    downres = 1,

    --proportion to fade towards black between frames
    --basically smaller = longer trails
    basic_fade_amount = 1,
}

-- random walk params for initialisation
local gen_params = {
    base = {
        walk_scale = 4,
        bigjump_scale = 13,
        bigjump_chance = 0.01,
        scatter_scale = 0.2,
    },
    dense = {
        bigjump_scale = 30,
        bigjump_chance = 0.01,
        scatter_scale = 0.1,
    },
    sparse = {
        walk_scale = 1,
        bigjump_scale = 35,
        bigjump_chance = 0.02,
        scatter_scale = 3,
    },
}

local fmt_t = {format="rgba32f"}

local function copy_img_to_canvas(img, canvas)
    lg.setCanvas(canvas)
    lg.setBlendMode("replace", "premultiplied")
    lg.draw(img)
    lg.setBlendMode("alpha", "alphamultiply")
    lg.setCanvas()
end


function Particles:new(args)
    --local x = args.x or args_defaults.x
    local dim = args.dim or args_defaults.dim
    local ntypes = args.ntypes or args_defaults.ntypes
    local gen = args.gen or args_defaults.gen
    local downres = args.downres or args_defaults.downres
    local basic_fade_amount = args.basic_fade_amount or args_defaults.basic_fade_amount

    -- generates a grid of points with uv coordinates to draw to
    -- generate the mesh used to render the particles
    local points = {}
    for y = 1, dim do
        for x = 1, dim do
            table.insert(points, {
                --x, y, -- position
                -- texturecoords uv
                (x - 0.5) / dim, (y -0.5) / dim
            })
        end
    end

    --generate the render buffer
    local sw, sh = lg.getDimensions()
    local rs = 1 / downres
    local rw, rh = sw * rs, sh * rs

    self = self:init({
        dat = lg.newCanvas(dim, dim, fmt_t),
        pos = lg.newCanvas(dim, dim, fmt_t),
        vel = lg.newCanvas(dim, dim, fmt_t),
        acc = lg.newCanvas(dim, dim, fmt_t),

        schema = {},

        shaders = {},

        -- render variables
        render_mesh = lg.newMesh(points, "points", "static"),
        render_cv = lg.newCanvas(rw, rh, {format="rgba16f"}),
        rw = rw, rh = rh, rs = rs,
        downres = downres,
        basic_fade_amount = basic_fade_amount,

        -- camera settings TODO abstract away
        cx = 0, cy = 0, zoom = 0.01,

        dim = dim,
        ntypes = ntypes,
        gen = gen,


        --some debug timing stuff
        update_time = 0,
        draw_time = 0,
    })

    -- generate the interaction schema
    self:init_schema()
    -- generate shaders for each interaction type
    self:genInteractionShaders()

    -- take the particle positions on a random walk and give them random types
    self:init_particles()

    self.render_shader = lg.newShader(from_template('src/shaders/render_template.glsl',
                                                    {dim=dim, rotate_frag=rotate_frag, ntypes=ntypes})
                                    )

    return self
end

function Particles:update(dt)
    --[[ EACH UPDATE CYCLE:
        0. start a timer
        1. clear particles.acc
        2. iterate through all interactions:
            drawing self.pos with the current interaction shader
            each pass (after the first) adding to self.acc through `alphamultiply`
        3. update velocity from acceleration
        4. update position from velocity
        5. clear the graphics settings
    --]]

    --put an upper cap on dt so we don't get any absurd jumps
    dt = math.min(dt, 1 / 60)
    --measure the update time we care about
    local update_time = self.update_time

    update_time = update_timer(update_time, 0.99, function()

        --accel_shader:send("sampling_percent", sampling_percent)

        -- clear the particles.acc image
        lg.setCanvas(self.acc)
        lg.setColor(1,1,1,1)
        lg.discard()

        for i, _table in ipairs(self.shaders) do
            for j, curr_shader in ipairs(_table) do

                --render next state
                lg.setShader(curr_shader)
                curr_shader:send("DataTex", self.dat)
                -- Each accel shader is specific to a pair of particle types
                -- perhaps I should feed in a pair of binary masks on the MainTex?

                -- on the first pass use replace- premultiplied
                -- cumulate acc on all subsequent passes
                if i == 1 then
                    lg.setBlendMode("replace", "premultiplied")
                else
                    lg.setBlendMode("add", "alphamultiply")
                end

                lg.setColor(1,1,1,1)
                lg.draw(self.pos)
            end
        end

        lg.setShader()
        lg.setBlendMode("add", "alphamultiply")
        lg.setColor(1,1,1,1)
        --integrate vel
        lg.setCanvas(self.vel)
        lg.draw(self.acc)
        --integrate pos
        lg.setCanvas(self.pos)
        lg.draw(self.vel)
        lg.setColor(1,1,1,1)


        end)
    lg.setCanvas()
    lg.setBlendMode("alpha", "alphamultiply")
    lg.setShader()
    lg.draw(self.pos)

    --pan
	local pan_amount = (50 / self.zoom) * dt
	if love.keyboard.isDown("up") then
		self.cy = self.cy - pan_amount
	end
	if love.keyboard.isDown("down") then
		self.cy = self.cy + pan_amount
	end
	--rotate
	local rotate_amount = math.pi * 0.5 * dt
	if love.keyboard.isDown("left") then
		self.cx = self.cx - rotate_amount
	end
	if love.keyboard.isDown("right") then
		self.cx = self.cx + rotate_amount
	end

	--zoom
	if love.keyboard.isDown("i") then
		self.zoom = self.zoom * 1.01
	end
	if love.keyboard.isDown("o") then
		self.zoom = self.zoom / 1.01
	end

end

function Particles:render()
    local render_shader = self.render_shader
    local draw_time = self.draw_time
    local rw, rh = self.rw, self.rh
    local zoom = self.zoom
    local render_shader = self.render_shader
    local cx, cy = self.cx, self.cy


    draw_time = update_timer(draw_time, 0.99, function()
        --fade render canvas one step
        lg.setBlendMode("alpha", "alphamultiply")
        lg.setCanvas(self.render_cv)
        local lum = 0.075
        lg.setColor(lum, lum, lum, self.basic_fade_amount)
        lg.rectangle("fill", 0, 0, rw, rh)
        lg.setColor(1,1,1,1)

        --draw current state into render canvas
        lg.push()

        lg.translate(rw * 0.5, rh * 0.5)
        lg.scale(zoom, zoom)
        lg.translate(0, -cy)
        lg.setShader(render_shader)
        if render_shader:hasUniform("CamRotation") then render_shader:send("CamRotation", cx) end
        if render_shader:hasUniform("DataTex") then render_shader:send("DataTex", self.dat) end

        lg.setBlendMode("add", "alphamultiply")
        self.render_mesh:setTexture(self.pos)
        lg.draw(self.render_mesh)
        lg.pop()

        --draw render canvas as-is
        lg.setCanvas()
        lg.setShader()
        lg.setBlendMode("alpha", "premultiplied")
        lg.setColor(1,1,1,1)
        lg.draw(
            self.render_cv,
            0, 0,
            0,
            self.downres, self.downres
        )
    end)

    --lg.draw(self.pos)
    -- draw debug data
    lg.setShader()
    lg.setBlendMode("alpha", "alphamultiply")
    local label = {'data', 'pos', 'vel', 'acc'}
    lg.setFont(lg.newFont(14))
    for i, tex in pairs({self.dat, self.pos, self.vel, self.acc}) do
        local w, h = tex:getDimensions( )
        lg.draw(tex, i*w)

        lg.print(label[i], i*w, h+10)
    end
end

--setup initial buffer state
function Particles:init_particles()
    local gen = self.gen
    local dim = self.dim
    local fmt = fmt_t.format

    local _gen = gen_params['base']
    local this_gen = gen_params[gen]
	local walk_scale = this_gen.walk_scale or _gen.walk_scale
	local bigjump_scale = this_gen.bigjump_scale or _gen.bigjump_scale
	local bigjump_chance = this_gen.bigjump_chance or _gen.bigjump_chance
	local scatter_scale = this_gen.scatter_scale or _gen.scatter_scale

	--spawn particles with random walk
	local pos_img = love.image.newImageData(dim, dim, fmt)
    local dat_img = love.image.newImageData(dim, dim, fmt)
	local _pos = {0, 0, 0}
	local _total = {0, 0, 0}
	pos_img:mapPixel(function(x, y, r, g, b, a)
		--random walk
		for i, v in ipairs(_pos) do
			_pos[i] = v + love.math.randomNormal(walk_scale, 0)
		end

		if love.math.random() < bigjump_chance then
			for i, v in ipairs(_pos) do
				_pos[i] = v + love.math.randomNormal(bigjump_scale, 0)
			end
		end

		r = _pos[1] + love.math.randomNormal(scatter_scale, 0)
		g = _pos[2] + love.math.randomNormal(scatter_scale, 0)
		b = _pos[3] + love.math.randomNormal(scatter_scale, 0)
		a = 1

		--note down for later
		_total[1] = _total[1] + r
		_total[2] = _total[2] + g
		_total[3] = _total[3] + b

		return r, g, b, a
	end)

    -- map mass and type data to the dat img
    dat_img:mapPixel(function(x, y, r, g, b, a)
        local mass = 1.0
        local type = love.math.random(0, self.ntypes) / self.ntypes

		r,g,b,a = mass, type, 1.0, 1.0

		return r, g, b, a
	end)

	--apply mean offset
	for i,v in ipairs(_total) do
		_total[i] = v / (dim * dim)
	end
	pos_img:mapPixel(function(x, y, r, g, b, a)
		r = r - _total[1]
		g = g - _total[2]
		b = b - _total[3]
		return r, g, b, a
	end)

    copy_img_to_canvas(lg.newImage(dat_img), self.dat)
	copy_img_to_canvas(lg.newImage(pos_img), self.pos)

	--zero out acc, vel
	lg.setCanvas(self.vel)
	lg.clear(0,0,0,1)
	lg.setCanvas(self.acc)
	lg.clear(0,0,0,1)

	--reset canvas
	lg.setCanvas()
end

-- initialise the interaction schema with ntypes*ntypes of interactions
function Particles:init_schema()
    local ntypes = self.ntypes

    for i=1, ntypes do
        for j=1, ntypes do
            if j == 1 then self.schema[i] = {} end

            local type = {love.math.random(-1, 1),   -- repel, neutral, attract
                          love.math.random(1,25),    -- magnitude
                          love.math.random(1,6) / 3  -- distance factor
                         }

            self.schema[i][j] = type
        end
    end

end

--------------------------------------------------------------------------------

--- loop through interaction types and make a shader for each
function Particles:genInteractionShaders()
    local ntypes = self.ntypes

    local _params = {
        dim = self.dim,
        ntypes = ntypes,
        rotate_frag = rotate_frag
    }

    local shaders = {}
    for i=1, ntypes do
        for j=1, ntypes do
            if j==1 then shaders[i] = {} end

            local kA, kB, kC = unpack(self.schema[i][j])
            --shallow copy _params
            local vars = {
                typei = i, typej = j,
                kA = kA, kB = kB, kC = kC,
            }
            for k,v in pairs(_params) do vars[k] = v end

            local sc = from_template('src/shaders/interaction_template.glsl', vars)
            shaders[i][j] = love.graphics.newShader(sc)
        end
    end
    print('shaders generated')

    self.shaders = shaders

end
