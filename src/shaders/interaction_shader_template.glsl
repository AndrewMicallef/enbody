//[[
/*
INTERACTION SHADER TEMPLATE

This shader assumes MainTex is the position image of all particles
Assumes all masses are equal

It requires
TypeTex -- the particle.typ image

*/

uniform Image MainTex;
uniform Image TypeTex;

uniform float dt;

uniform float sampling_percent;
uniform float sampling_percent_offset;
const int dim = //]]..dim..[[;

#ifdef PIXEL

vec3 interaction(float type1, float type2, float r, vec3 dir, float m1 = 1.0, float m2 = 1.0) {
    // TODO adjust based on type, switch / LUT?
    if ((type1 == [[.. type1 ..]]) && (type2 == [[.. type2 ..]])) {
        // TODO replace with appropriate code for type1 - type2 interaction
        vec3 f = -(dir * m1 * m2 / (r * r)) * 10.0;
        return f;
    }
    else {
        return vec3(0.0);
    }
}

//]]..rotate_frag..[[

void effect() {
    //get our position & identity (type)
    vec3 my_pos = Texel(MainTex, VaryingTexCoord.xy).xyz;
    float my_type = Texel(TypeTex, VaryingTexCoord.xy).x;
    float m1 = 1.0;

    float sample_accum = sampling_percent_offset;

    float current_force_scale = force_scale / sampling_percent;

    //iterate all particles
    for (int y = 0; y < dim; y++) {
        for (int x = 0; x < dim; x++) {
            sample_accum = sample_accum + sampling_percent;
            if (sample_accum >= 1.0) {
                sample_accum -= 1.0;

                vec2 other_uv = (vec2(x, y) + vec2(0.5, 0.5)) / float(dim);
                vec3 other_pos = Texel(MainTex, other_uv).xyz;
                float other_type = Texel(TypeTex, other_uv).x;

                //get normalised direction and distance
                vec3 dir = other_pos - my_pos;
                float r = length(dir) / force_distance;
                if (r > 0.0 && ) {
                    dir = normalize(dir);

                    //vec3 f = dir;
                    // calculates
                    vec3 f = interaction(my_type, other_type, r, dir);
                    acc += (f / m1) * current_force_scale;
                }
            }
        }
    }
    love_PixelColor = vec4(acc, 1.0);
}
#endif
//]]
