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

    -- take the particle positions on a random walk and give them random types
    self:spawn_particles(gen, dim, fmt_t.format)

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
function Particles:spawn_particles(gen, dim, fmt)
    local _gen = gen_params['base']
    local this_gen = gen_params[gen]
	local walk_scale = this_gen.walk_scale or _gen.walk_scale
	local bigjump_scale = this_gen.bigjump_scale or _gen.bigjump_scale
	local bigjump_chance = this_gen.bigjump_chance or _gen.bigjump_chance
	local scatter_scale = this_gen.scatter_scale or _gen.scatter_scale

	local function copy_img_to_canvas(img, canvas)
		lg.setCanvas(canvas)
		lg.setBlendMode("replace", "premultiplied")
		lg.draw(img)
		lg.setBlendMode("alpha", "alphamultiply")
		lg.setCanvas()
	end

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

		r = mass
		g = type
		b = 1.0
		a = 1

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

-- TODO
interaction_shaders = {}
for k,v in pairs(sim_configs) do
	local accel_shader = lg.newShader([[
	uniform Image MainTex;
	const float timescale = ]]..timescale..[[;
	const float force_scale = ]]..v.force_scale..[[;
	const float force_distance = ]]..v.force_distance..[[;
	uniform float dt;

	uniform float sampling_percent;
	uniform float sampling_percent_offset;
	const int dim = ]]..dim..[[;
	#ifdef PIXEL
	const float mass_scale = ]]..v.mass_scale..[[;
	float mass(float u) {
		return mix(1.0, mass_scale, ]]..v.mass_distribution..[[);
	}

	]]..rotate_frag..[[

	void effect() {
		//get our position
		vec3 pos = Texel(MainTex, VaryingTexCoord.xy).xyz;
		float my_mass = mass(VaryingTexCoord.x);

		float sample_accum = sampling_percent_offset;

		float current_force_scale = force_scale / sampling_percent;
		]]..(v.constant_term or "vec3 acc = vec3(0.0);")..[[

		//iterate all particles
		for (int y = 0; y < dim; y++) {
			for (int x = 0; x < dim; x++) {
				sample_accum = sample_accum + sampling_percent;
				if (sample_accum >= 1.0) {
					sample_accum -= 1.0;

					vec2 ouv = (vec2(x, y) + vec2(0.5, 0.5)) / float(dim);
					vec3 other_pos = Texel(MainTex, ouv).xyz;
					//define mass quantities
					float m1 = my_mass;
					float m2 = mass(ouv.x);
					//get normalised direction and distance
					vec3 dir = other_pos - pos;
					float r = length(dir) / force_distance;
					if (r > 0.0) {
						dir = normalize(dir);
						]]..(v.force_term or "vec3 f = dir;")..[[
						acc += (f / m1) * current_force_scale;
					}
				}
			}
		}
		love_PixelColor = vec4(acc, 1.0);
	}
	#endif
	]])
	table.insert(interaction_shaders, {
		name = k,
		accel_shader = accel_shader,
		gen = v.gen,
	})
end
