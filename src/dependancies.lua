require('lib.batteries'):export()

lg = love.graphics

lg.setDefaultFilter("nearest", "nearest")

require 'src.Particles'


--------------------------------------------------------------------------------

--format for simulation configurations
local sim_template = {
	--which worldgen to use
	gen = "dense",
	--stronger or weaker forces
	force_scale = 1.0,
	--distance scale forces act over
	force_distance = 10.0,
	--the term included in the shader inline; determines the "style" of force
	force_term = "vec3 f = dir;",
	--scale of masses present
	--1 = all particles are same mass
	--500 = particles mass between 1 and 500
	mass_scale = 1.0,
	--the term included in the shader that
	--determines the distribution of particle masses
	mass_distribution = "u * u",
}
local sim_configs = {
	gravity = {
		gen = "dense",
		force_scale = 1.0,
		force_distance = 10.0,
		force_term = "vec3 f = dir * (m1 * m2) / max(1.0, r * r);",
		mass_scale = 1.0,
		mass_distribution = "u * u",
	},
	strings = {
		gen = "sparse",
		force_scale = 0.00005,
		force_distance = 20.0,
		force_term = "vec3 f = dir * m2 * max(1.0, r * r);",
		mass_scale = 5.0,
		mass_distribution = "u",
	},
	cloud = {
		gen = "dense",
		force_scale = 0.01,
		force_distance = 10.0,
		force_term = "vec3 f = dir * (r * m1 * 0.3 - 5.0);",
		mass_scale = 2.0,
		mass_distribution = "u",
	},
	boids = {
		gen = "dense",
		force_scale = 0.3,
		force_distance = 10.0,
		force_term = "vec3 f = dir / max(1.0, r);",
		mass_scale = 2.0,
		mass_distribution = "u",
	},
	shy = {
		gen = "dense",
		force_scale = 0.05,
		force_distance = 5.0,
		force_term = "vec3 f = dir * float(r > 2.0);",
		mass_scale = 2.0,
		mass_distribution = "u",
	},
	atoms = {
		gen = "dense",
		force_scale = 0.5,
		force_distance = 15.0,
		force_term = "vec3 f = dir * float(r < 2.0);",
		mass_scale = 10.0,
		mass_distribution = "u",
	},
	sines = {
		gen = "dense",
		force_scale = 0.1,
		force_distance = 40.0,
		force_term = "vec3 f = dir * sin(r);",
		mass_scale = 10.0,
		mass_distribution = "u",
	},
	cosines = {
		gen = "sparse",
		force_scale = 0.05,
		force_distance = 25.0,
		force_term = "vec3 f = dir * m2 * -cos(r);",
		mass_scale = 10.0,
		mass_distribution = "u",
	},
	spiral = {
		gen = "sparse",
		force_scale = 0.01,
		force_distance = 5.0,
		force_term = "vec3 f = dir * m2 + vec3(rotate(dir.xy, 0.025 * m1 * 3.14159), dir.z) * 0.5;",
		mass_scale = 5.0,
		mass_distribution = "u",
	},
	center_avoid = {
		gen = "sparse",
		force_scale = 1.0,
		force_distance = 1.0,
		constant_term = "vec3 acc = -pos; acc = acc / (length(acc) * 0.1);",
		force_term = "vec3 f = -(dir * m1 * m2 / (r * r)) * 10.0;",
		mass_scale = 1.0,
		mass_distribution = "u",
	},
	nebula = {
		gen = "dense",
		force_scale = 1.0,
		force_distance = 2.0,
		force_term = [[
			float factor = min(mix(-m2, 1.0, r), 1.0) / max(0.1, r * r) * m1;
			vec3 f = dir * factor;
		]],
		mass_scale = 30.0,
		mass_distribution = "u",
	},
}

--------------------------------------------------------------------------------

--parameters of worldgen
local gen_configs = {
	dense = {
		walk_scale = 3,
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


--------------------------------------------------------------------------------

-- takes a file containing template tokens of the form {{var}}
-- and fills the tokens from the subs table given {var =  val} is in subs
function from_template(template_file, subs)
	local template = love.filesystem.read(template_file)
	local filled = string.gsub(template, "{{(%w+)}}", subs)
	return filled
end

-- timing function used in Particles update and draw
function update_timer(current_timer, lerp_amount, f)
	local time_start = love.timer.getTime()
	f()
	local time_end = love.timer.getTime()
	return current_timer * (1 - lerp_amount) + (time_end - time_start) * lerp_amount

end
