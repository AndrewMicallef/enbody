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
uniform float dt;

const int dim = {{dim}};

// function to get the integer type from the data vector
int getType(vec3 dat) {
    return floor(dat.x * {{ntypes}});
}

//
float getInteraction(int t1, int t2, float m1, float m2, vec3 dir, float r) {
    if (t1 == {{typei}} && t2 == {{typej}}) {
        return {{kA}} * dir * (m1 * m2 * {{kB}}) / (r * r * {{kC}});
    }
    else {
        return 0.0;
    }
}

#ifdef PIXEL

{{rotate_frag}}

void effect() {
    //get our position
    vec3 pos = Texel(MainTex, VaryingTexCoord.xy).xyz;
    vec3 dat = Texel(DataTex, VaryingTexCoord.xy).xyz;
    float m1 = dat.x;
    int t1 = getType(dat);

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

            if (r > 0.0) {
                dir = normalize(dir);
                float f = getInteraction(t1, t2, m1, m2, dir, r);
                acc += (f / m1);
            }
        }
    }
    love_PixelColor = vec4(acc, 1.0);
}
#endif
