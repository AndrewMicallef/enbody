/*

*/
uniform float uTime;             // Time in seconds (for use in seeding the random function)
uniform Image OrganismTex; // Image Data of the macro organism [self, outbound, inbound]
uniform Image AgentTex;    // The Agent data [locx, locy, heading, X]
uniform Image FloorTex;    // The Data 8bit image [trial, X,X]
//uniform float dt;

const float TAU = 6.28318530717958647692528; // 2*Pi
const float PHI = 1.61803398874989484820459; // Φ = Golden Ratio [gould random function]

const int ww = textureSize(FloorTex).x;
const int hh = textureSize(FloorTex).y;
const float w_float = float ww;
const float h_float = float hh;
const float onepx = 1 / min(ww, hh);

const float pTurningAngle = TAU * 0.25;
const float pSenseRadius =  onepx;
const float pSenseAngle = TAU * 0.15;
const float pMoveSpeed = onepx;

const float pDepositVal = 1/20;


#ifdef PIXEL

void effect() {
    //Extract Agent and Floor data from texture for this data block
    vec2 xy = VaryingTexCoord.xy;
    float dTrail = 0;

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

    // defuse
    // decay

    love_PixelColor = vec4(pos.x, pos.y, heading, agent.w);
}


#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
