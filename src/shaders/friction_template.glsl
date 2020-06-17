/*
FRICTION SHADER TEMPLATE

This shader expects to be drawn on a position image.

MainTex is assumed to be the Particles.vel image

send data required:

DataTex -- Particles.dat image

friction is proportional to - v^2

this template uses the dual curley braces pattern {{X}} for replacements.
The following replacements are required to be made in this template:

dim -- (integer) dimension of the position and data image
ntypes -- (integer) the number of particle types in this universe

*/

uniform Image MainTex;    // The position image
uniform Image DataTex;    // The Data image [mass, type, X, X]
//uniform float dt;

const int dim = {{dim}};

#ifdef PIXEL

void effect() {
    //get our position
    vec3 vel = Texel(MainTex, VaryingTexCoord.xy).xyz;
    vec3 dat = Texel(DataTex, VaryingTexCoord.xy).xyz;

    float mass = dat.x;
    float drag_coefficient = dat.z;

    vec3 f;
    vec3 acc;
    vec3 dir = normalize(vel);
    float v = length(vel);

    acc = -(vel * vel * vel * drag_coefficient);

    love_PixelColor = vec4(acc, 1.0);
}

#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
