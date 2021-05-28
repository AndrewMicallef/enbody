# Tasks

- [X] Make an interaction schema generator  
    **Specifications:**
    - `N x N x 3` matrix, where `N` is number of particle types
    - `interaction[i][j]` defines the three components of the interaction between
       particle of type `i` and particles of type `j`.

    - In the first instance the parameters will describe:
        1. the decay rate of the force with respect to distance
        2. scale of the force (+ve for attraction, -ve for repulsive)
        3. free parameter for a later decision

- [X] redirect one of the interaction parameters to a friction like coefficient
- [ ] add fps counter
- [ ] upgrade camera controls: add pan / trackball rotation
- [ ] put depth / perspective back into the render




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

--------------------------------------------------------------------------------

**2020 - 06 - 17**

I don't understand how the renderer works, but at this point I think I can move
on, because it works. I fixed it by removing the UV coordinates I had added to
the points which comprise `render_mesh`.


So the first run appears to have all particles fling out in a massive
decompression. One big bang. That's cool and all, but I want to
1. Limit the amount of space for them to expand into, either have them walled in
   or create a circular universe.
2. Add a frictional force that slows the rate of expansion. It is not clear if
   there are any attractive forces in the first run, we should fix that.



````````````````
What I want to do is run a simple simulation in a shader. The simulation is based on the physarium movement and a rough implementation of the model described [here](https://sagejenson.com/physarum).

In my implementation I am starting with two images, the first contains data about agents (heading, posx, posy, ...) The second image is a world texture which the agents interact with...
@Max I'm actually writting this based on enbody
Max
 —
Today at 9:30 AM
float as general bit patterns is only a good idea within their integer range; you can do https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/floatBitsToInt.xhtml but it needs glsl3 and afaik might get weird with nans
yeah i remember you being interested in enbody a while ago :slight_smile:
AndrewMicallef
 —
Today at 9:30 AM
yeah thanks to lockdown 4 I have time for this agin :stuck_out_tongue:
Max
 —
Today at 9:30 AM
you in melbourne too :upside_down:
AndrewMicallef
 —
Today at 9:30 AM
so I have a lot of boolean data that I want to pack into the world texture
like: "is this a wall, is this grass, is this water, ...blah blah"
too much for a single image, but if i can interpret the indivitual bits of a single channel I easily have the room for everything i want to encode
ya melbourne
Max
 —  —
Today at 9:33 AM
Why not use a byte format for the texture
Max
 —
Today at 9:33 AM
@AndrewMicallef you definitely can use the bits of an individual channel; if you use one of the fixed point texture formats there's no issues other than knowing if you're storing linear or srgb data
(ie r8 rg8 rgba8 or r16 rg16)

AndrewMicallef
 —
Today at 9:33 AM
How do i find the 'integer range' of a float?
Max
 —
Today at 9:34 AM
er what i meant to say was more "dont use float for bit patterns if you can help it"
AndrewMicallef
 —
Today at 9:34 AM
Ok, when i was reading the love wiki it seamed like all images were floats,
Max
 —
Today at 9:34 AM
use one of the formats above and then multiply it out from the 0-1 range to the 0-255 or 0-65535 range
well
AndrewMicallef
 —
Today at 9:34 AM
so can I transfer integers with say r8?
Max
 —
Today at 9:34 AM
in glsl you will "get" the result as a float from 0-1
but you can multiply it safely to 0-255 and then mask out bits
AndrewMicallef
 —
Today at 9:35 AM
ok
Max
 —
Today at 9:35 AM
because the full range therein will be stored in the r8 texture
(as boring old bytes)
AndrewMicallef
 —
Today at 9:35 AM
I just want boring bytes
:stuck_out_tongue:
Max
 —
Today at 9:35 AM
it's just automagically turned into an 0-1 range when sampling from the texture because it's assumed you wanted to store image data in there
and love doesn't have integer texture formats, so doing the multiply is as good as you're going to get
AndrewMicallef
 —
Today at 9:36 AM
Aright this should be what I need. Well it seams like either I will get this done this week, or you won't hear from me till next lockdown :stuck_out_tongue:
thanks @Max

````````
