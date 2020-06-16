1. Reduces simulation to single type of universe

# Tasks

- [ ] Make an interaction schema generator  
    **Specifications:**
    - `N x N x 3` matrix, where `N` is number of particle types
    - `interaction[i][j]` defines the three components of the interaction between
       particle of type `i` and particles of type `j`.

    - In the first instance the parameters will describe:
        1. the decay rate of the force with respect to distance
        2. scale of the force (+ve for attraction, -ve for repulsive)
        3. free parameter for a later decision



# Notes

-----

**2020 - 06 - 13**

Max would suggest to have a new image for each type of particle and to calculate
all like interactions simultaneously.

In a world with 3 particles; A, B, C

      interaction_matrix =
            A    B    C
        A   0   .5    1

        B  .5    0   .5

        C   1   .5    0

So in this schema like particles have an interaction parameter of 0, which would
cause them to repel each other. An interaction parameter of 1 would imply an
attractive force. An interaction parameter of 0.5 would imply no force, or a
neutral interaction.
Thus:  
- `A` *repels* `A`
- `A` *ignores* `B`
- `A` *attracts* `C`  
In the above schema the interaction matrix is symmetrical, but this need not be
so. In fact asymmetry in the interaction terms would produce behaviour that is
likely to be more interesting.


## Building on [`enbody`](https://github.com/1bardesign/enbody)

`particles` are defined as a collection of three images `rgba32f`. Or alternatively the
universe of particles is a set of matrices.

`particles` has three fields (images).
- `particles.pos` gives the position vector of each particle
- `particles.vel` gives the current velocity vector of each particle
- `particles.acc` gives the current acceleration vector of each particle

Each image has a shader applied to it in turn and the overall render pipeline
runs as follows:
1. set the acceleration shader: set particles.acc canvas : draw particles.pos
2. clear the shader
    - add particle.vel to particle.acc
    - add particle.pos to particle.vel

```lua
--render next state
lg.setShader(accel_shader)

-- Note: shader:send() allows data to be sent to the shader
-- this can be numbers, vectors, matricies, images... Highley usefull
accel_shader:send("sampling_percent_offset", love.math.random())


-- draw particle position onto acceleration canvas using the acceleration shader
-- thus within `accel_shader` `MainTex` -> `particle.pos,
-- as per the [FM] (https://love2d.org/wiki/Shader_Variables): see notes under
-- Pixel Shader built-in variables
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
```

In my version I would have additional blends for each interaction in order to
compute an `Fnet`. So I would need to run separate shaders for `F_AA`, `F_AB`,
`F_AC`, `F_BA`, ..., `F_CC`.

So my universe of `particles` table has now expanded to include all those fields.
For a small universe of three particles I may get away with this, but this
strategy ultimately doesn't scale in a memory friendly way. For Each new particle
I am doubling the number of images and the size of each image...This can explode
into all my memory.

So all that begins by adding the following to the initialisation code:
```lua
--format of the buffer textures
local fmt_t = {format="rgba32f"}
--set up separate buffers
local particles = {
	pos = lg.newCanvas(dim, dim, fmt_t),
	vel = lg.newCanvas(dim, dim, fmt_t),
	acc = lg.newCanvas(dim, dim, fmt_t),
	Fnet = lg.newCanvas(dim, dim, fmt_t),                           --  <<<
}

local types = {'A', 'B', 'C'}                                       --  <<<
for _, i in ipairs(types) do                                        --  <<<  
	for _, j in ipairs(types) do                                    --  <<<      
		particles['F_' .. i .. j] = lg.newCanvas(dim, dim, fmt_t)   --  <<<
	end                                                             --  <<<
end                                                                 --  <<<

```

--------------------------------------------------------------------------------

**2020 - 06 - 14**

So my interaction shader was going to be built around a function like this:

```C
vec3 interaction(float typ, float other_typ, float r, vec3 dir, float m1, float m2) {
    // TODO adjust based on type, switch / LUT?
    vec3 f = -(dir * m1 * m2 / (r * r)) * 10.0;
    return f;
}


//iterate all particles
for (int y = 0; y < dim; y++) {
    for (int x = 0; x < dim; x++) {
        vec3 f = interaction(...);
    }
}
```

I think I need to know the type of this particle and the type of every other
particle that I am comparing it to. However by splitting the forces up as I have
above I am going to have a new shader for each interaction image.

The interaction term is going to be specified by the rgb parameters of the
interaction image. For the time being I will begin with the interaction schema
described above.


Interaction schema is an NxNx3 matrix of the interaction parameters between particles
of type i, j. Interactions produce forces. Forces are specific to each particle,
and are composed of components from each interaction.
So The force matrix has diminsions:
`dim` number of particles * 'number of types'
`dim`x`dim`x`N`


Particles are currently being reworked into a `Particles` class thanks to
batteries. The `Particles` class is a container for multiple images,
- `dat` rgba --> mass, type, X, X
- `pos` rgba --> x, y, z, X
- `vel` rgba --> dx, dy, dz, X
- `acc` rgba --> ddx, ddy, ddz, X
(where X is unused)



---

**2020 - 06 - 16**

from discord this morning

`Max` comments

> @AndrewMicallef you can avoid all the separate textures by clearing and then
> adding your forces per-particle into a single acceleration texture, then
> adding that to the velocity and velocity to the position as normal

> i'd recommend your interaction matrix be normalised -1, 0, 1 rather than have
> 0.5 normalised but i guess it's a matter of semantics

`Moonfly` adds:
> By extension, half of the floating-point numbers are in the interval [-1,1]

`Max` continues
> i recommend having an image for each type of particle btw, not each separate
> particle, but i think you get this already

* looking at update then render cycles in turn
