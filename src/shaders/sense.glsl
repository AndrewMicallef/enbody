/*
INTERACTION SHADER TEMPLATE

This shader expects to be drawn on a position image.

AgentTex is assumed to be the Particles.pos image

send data required:

FloorTex -- Particles.dat image
dt -- the time delat for this update step

this template uses the dual curley braces pattern {{X}} for replacements.
The following replacements are required to be made in this template:

dim -- (integer) dimension of the position and data image
ntypes -- (integer) the number of particle types in this universe

typei -- (integer) the particle type of the affected particle
typej -- (integer) the particle type of the effector particle

kA -- (integer) These three paramaters affect the direction,
kB -- (integer) magnitude,
kC -- (integer) and distance falloff of the interaction force


rotate_frag -- (shader code) fragment of shader code to affect rotation

*/

uniform Image AgentTex;    // The Agent data [locx, locy, heading, X]
uniform Image FloorTex;    // The Data 8bit image [trial, resource, X,X]
//uniform float dt;

// function to get the integer type from the data vector
int getType(vec3 dat) {
    return int(floor(dat.y * {{ntypes}}));
}

#ifdef PIXEL

vec2 rotate(vec2 v, float t) {
	float s = sin(t);
	float c = cos(t);
	return vec2(
		c * v.x - s * v.y,
		s * v.x + c * v.y
	);
}

void effect() {
    //Extract Agent and Floor data from texture for this data block
    vec2 thisblock = VaryingTexCoord.xy

    vec4 agent = Texel(AgentTex, thisblock);
        float heading = agent.z;
        vec2 pos = agent.xy;

    vec4 floor = Texel(FloorTex, thisblock);
        float fl_trail = floor.x;
        float fl_resource = floor.y;

    //1. sensors need to sample from adjacent floor tiles...
    // in the first instance let's go with 3 sensors
    // L - F - R:  located at -0.5, 0, 0.5 radians
    // texelFetch gets me the value at a pixel exact
    // texel takes a float argument and blends the result.
    // for sensors I want the blended result.
    for (int t = 0; t <= 2; t++) {
        offset = (t-0.5)
        vec4 _ = texel(FloorTex, thisblock + offset)
    }
    //2. compute new position and heading based on previous data...
    // output new data
    love_PixelColor = vec4(pos.x, pos.y, heading, agent.w);
}

#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
