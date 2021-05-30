#pragma language glsl3
/*

*/
uniform Image AgentTex;    // The Agent data [locx, locy, heading, X]
uniform Image FloorTex;    // The Data 8bit image [trial, X,X]
//uniform float dt;

const float TAU = 6.28318530717958647692528; // 2*Pi
const float PHI = 1.61803398874989484820459; // Φ = Golden Ratio [gould random function]

int ww = textureSize(FloorTex, 0).x;
int hh = textureSize(FloorTex, 0).y;
float w_float = float(ww);
float h_float = float(hh);
float onepx = 1 / min(w_float, h_float);

const float pDepositVal = 1/20;


#ifdef PIXEL

void effect() {
    //Extract Agent and Floor data from texture for this data block
    vec2 xy = VaryingTexCoord.xy;
    float dTrail = 0;

    vec4 floor = Texel(FloorTex, xy);

    // deposit
    for (int i = 0; i < ww; i++){
        for (int j = 0; j < hh; j++){
            // https://stackoverflow.com/questions/33270823/how-to-cast-int-to-float-in-glsl-webgl
            float u = float(i) / w_float;
            float v = float(j) / h_float;
            vec2 agent_pos = Texel(AgentTex, vec2(u, v)).xy;

            if (distance(agent_pos, xy) <= onepx) {
                dTrail += pDepositVal;
            }
        }
    }
    floor.x += dTrail;

    love_PixelColor = floor;
}


#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
