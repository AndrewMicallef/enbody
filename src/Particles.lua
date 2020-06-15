Particles = class()

local args_defaults = {
    --dimension of the particles textures
    dim = 64,

    --number of discrete particle types
    ntypes = 2,

    -- type of spawn distribution
    gen = 'base',

    --amount to downres the render buffer
    downres = 2,

    --proportion to fade towards black between frames
    --basically smaller = longer trails
    basic_fade_amount = 0.1,
}

-- random walk params for initialisation
local gen_params = {
    base = {
        walk_scale = 3,
        bigjump_scale = 3,
        bigjump_chance = 0,
        scatter_scale = 0.2,
    },
    dense = {
        bigjump_scale = 30,
        bigjump_chance = 0.01,
        scatter_scale = 0.1,
    }
}

local fmt_t = {format="rgba32f"}

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
                x, y, -- position
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

        render_mesh = lg.newMesh(points, "points", "static"),
        render_cv = lg.newCanvas(rw, rh, {format="rgba16f"}),

        dim = dim,
        ntypes = ntypes,
        gen = gen,
        downres = downres,
        basic_fade_amount = basic_fade_amount,

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


    return self
end

function Particles:update(dt)
    --put an upper cap on dt so we don't get any absurd jumps
    dt = math.min(dt, 1 / 60)
    --measure the update time we care about
    local update_time = self.update_time
    update_time = update_timer(update_time, 0.99, function()

        --accel_shader:send("sampling_percent", sampling_percent)

        for i, accel_shader in ipairs(interaction_shaders) do

            --render next state
            lg.setShader(accel_shader)
            accel_shader:send("DataTex", self.dat)
            -- Each accel shader is specific to a pair of particle types
            -- perhaps I should feed in a pair of binary masks on the MainTex?

            lg.setBlendMode("replace", "premultiplied")
            lg.setColor(1,1,1,1)
            lg.setCanvas(particles.acc)
            lg.draw(particles.pos)

            --
            lg.setShader()
            lg.setBlendMode("add", "alphamultiply")
            lg.setColor(1,1,1,actual_dt)
            --integrate vel
            lg.setCanvas(particles.vel)
            lg.draw(particles.acc)
            --integrate pos
            lg.setCanvas(particles.pos)
            lg.draw(particles.vel)
        end
        lg.setColor(1,1,1,1)
    end)
    lg.setCanvas()
    lg.setBlendMode("alpha", "alphamultiply")
    lg.setShader()
end

function Particles:render()
    local draw_time = self.draw_time

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
        if render_shader:hasUniform("VelocityTex") then render_shader:send("VelocityTex", self.vel) end

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
        lg.setShader()
        lg.setBlendMode("alpha", "alphamultiply")
    end)
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
        local type = love.math.random(0, self.types) / self.types

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
Particles.render_shader = lg.newShader([[
uniform Image MainTex;
uniform Image VelocityTex;
uniform float CamRotation;
const int dim = ]]..dim..[[;

]]..rotate_frag..[[

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	vec2 uv = vertex_position.xy;
	vec3 pos = Texel(MainTex, uv).xyz;
	vec3 vel = Texel(VelocityTex, uv).xyz;

	//rotate with camera
	pos.xz = rotate(pos.xz, CamRotation);

	//perspective
	float near = -500.0;
	float far = 500.0;
	float depth = (pos.z - near) / (far - near);
	if (depth < 0.0) {
		//clip
		return vec4(0.0 / 0.0);
	} else {
		vertex_position.xy = pos.xy / mix(0.25, 2.0, depth);
	}

	//derive colour
	float it = length(vel) * 0.1;
	float clamped_it = clamp(it, 0.0, 1.0);

	float i = (uv.x + uv.y * float(dim)) / float(dim);
	i += length(pos) * 0.001;
	i *= 3.14159 * 2.0;

	VaryingColor.rgb = mix(
		vec3(
			(cos(i + 0.0) + 1.0) / 2.0,
			(cos(i + 2.0) + 1.0) / 2.0,
			(cos(i + 4.0) + 1.0) / 2.0
		) * clamped_it,
		vec3(1.0),
		sqrt(it) * 0.01
	);
	VaryingColor.a = (it * 0.1) * (1.0 - depth);

	//debug
	//VaryingColor = vec4(1.0);

	return transform_projection * vertex_position;
}
#endif
#ifdef PIXEL
void effect() {
	love_PixelColor = VaryingColor;
}
#endif
]])

-- Utilities

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
            if j == 1 then shaders[i] = {} end

                local kA, kB, kC, _ = self.schema[i][j]
                print('interaction params:' .. kA ..', '.. kB .. ', '.. kC)
                --shallow copy _params
                local vars = {
                    typei = i, typej = j,
                    kA = kA, kB = kB, kC = kC,
                }
                for k,v in pairs(_params) do vars[k] = v end

                shaders[i][j] = genInteractionShader(vars)
        end
    end

    self.shaders = shaders

end



local function genInteractionShader(vars)
    assert(vars.dim, "usage: genInteractionShader{dim, ntypes, typei, typej, kA, kB, kC, rotate_frag}\n"
                    .. "missing <dim> paramater")
    assert(vars.ntypes, "usage: genInteractionShader{dim, ntypes, typei, typej, kA, kB, kC, rotate_frag}\n"
                     .. "missing <ntypes> paramater")
    assert(vars.typei, "usage: genInteractionShader{dim, ntypes, typei, typej, kA, kB, kC, rotate_frag}\n"
                    .. "missing <typei> paramater")
    assert(vars.typej, "usage: genInteractionShader{dim, ntypes, typei, typej, kA, kB, kC, rotate_frag}\n"
                    .. "missing <typej> paramater")
    assert(vars.kA, "usage: genInteractionShader{dim, ntypes, typei, typej, kA, kB, kC, rotate_frag}\n"
                    .. "missing <kA> paramater")
    assert(vars.kB, "usage: genInteractionShader{dim, ntypes, typei, typej, kA, kB, kC, rotate_frag}\n"
                    .. "missing <kB> paramater")
    assert(vars.kC, "usage: genInteractionShader{dim, ntypes, typei, typej, kA, kB, kC, rotate_frag}\n"
                    .. "missing <kC> paramater")
    assert(vars.rotate_frag, "usage: genInteractionShader{dim, ntypes, typei, typej, kA, kB, kC, rotate_frag}\n"
                    .. "missing <rotate_frag> paramater")

    local template = love.filesystem.read('src/shaders/interaction_template.glsl')
    local shadercode = string.gsub(template, "{{(%w+)}}", vars)

    return love.graphics.newShader(shadercode)
end

local function copy_img_to_canvas(img, canvas)
    lg.setCanvas(canvas)
    lg.setBlendMode("replace", "premultiplied")
    lg.draw(img)
    lg.setBlendMode("alpha", "alphamultiply")
    lg.setCanvas()
end
