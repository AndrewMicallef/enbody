/*

ELECTROSTATIC FORCE SHADER TEMPLATE

This shader expects to be drawn on a position image.

MainTex is assumed to be the Particles.pos image

send data required:

DataTex -- Particles.dat image
dt -- the time delat for this update step

this template uses the dual curley braces pattern {{X}} for replacements.
The following replacements are required to be made in this template:

dim -- (integer) dimension of the position and data image

*/

uniform Image MainTex;    // The position image
uniform Image DataTex;    // The Data image [mass, type, X, X]
//uniform float dt;

const int dim = {{dim}};

#ifdef PIXEL

void effect() {
    //get our position
    vec3 pos = Texel(MainTex, VaryingTexCoord.xy).xyz;
    vec3 dat = Texel(DataTex, VaryingTexCoord.xy).xyz;
    float m1 = dat.x;
	int c1 = int(floor(dat.y));

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
			int c2 = int(floor(dat.y));
            //get normalised direction and distance
            vec3 dir = other_pos - pos;
            float r = length(dir);

            if (r > 100.0 )  {
                dir = normalize(dir);
				// https://en.wikipedia.org/wiki/Electric_field
                f = dir * (c1 * c2) / r;
				f = clamp(f, -1e1, 1e1);
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
