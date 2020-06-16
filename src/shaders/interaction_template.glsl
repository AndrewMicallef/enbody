/*
INTERACTION SHADER TEMPLATE

This shader expects to be drawn on a position image.

MainTex is assumed to be the Particles.pos image

send data required:

DataTex -- Particles.dat image
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

uniform Image MainTex;    // The position image
uniform Image DataTex;    // The Data image [mass, type, X, X]
//uniform float dt;

const int dim = {{dim}};

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
    //get our position
    vec3 pos = Texel(MainTex, VaryingTexCoord.xy).xyz;
    vec3 dat = Texel(DataTex, VaryingTexCoord.xy).xyz;
    float m1 = dat.x;
    int t1 = getType(dat);

    // read off acc directly?
    vec3 acc = vec3(0.0);
    vec3 f;


    //iterate all particles
    for (int y = 0; y < dim; y++) {
        for (int x = 0; x < dim; x++) {

            vec2 other_uv = (vec2(x, y) + vec2(0.5, 0.5)) / float(dim);
            vec3 other_pos = Texel(MainTex, other_uv).xyz;
            vec3 other_dat = Texel(DataTex, other_uv).xyz;

            //define mass quantities
            float m2 = other_dat.x;
            float t2 = getType(other_dat);
            //get normalised direction and distance
            vec3 dir = other_pos - pos;
            float r = length(dir);

            if (t1 == {{typei}} && t2 == {{typej}} && r > 0.0 )  {
                dir = normalize(dir);
                f = {{kA}} * dir * (m1 * m2 * {{kB}}) / (r * r * {{kC}});
                acc += (f / m1);
            }
        }
    }
    love_PixelColor = vec4(acc, 1.0);
}

#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
