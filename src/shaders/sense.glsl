#pragma language glsl3
/*

*/
uniform float uTime;       // Time in seconds (for use in seeding the random function)
uniform Image AgentTex;    // The Agent data [locx, locy, heading, X]
uniform Image FloorTex;    // The Data 8bit image [trial, X,X]
uniform float dt;

const float TAU = 6.28318530717958647692528; // 2*Pi
const float PHI = 1.61803398874989484820459; // Φ = Golden Ratio [gould random function]

int ww = textureSize(FloorTex, 0).x;
int hh = textureSize(FloorTex, 0).y;
float w_float = float(ww);
float h_float = float(hh);
float onepx = 1 / min(w_float, h_float);

const float pTurningAngle = TAU * 0.25;
const float pSenseAngle = TAU * 0.15;
float pSenseRadius =  onepx;
float pMoveSpeed = onepx;

vec3 sense_trail(float heading, Image FloorTex, vec2 coordinates){

    vec2 offsetL = pSenseRadius * vec2(cos(heading-pSenseAngle), sin(heading-pSenseAngle));
    vec2 offsetF = pSenseRadius * vec2(cos(heading), sin(heading));
    vec2 offsetR = pSenseRadius * vec2(cos(heading+pSenseAngle), sin(heading+pSenseAngle));

    return vec3(
            Texel(FloorTex, coordinates + offsetL).x,
            Texel(FloorTex, coordinates + offsetF).x,
            Texel(FloorTex, coordinates + offsetR).x
        );
}

// Gold Noise ©2015 dcerisano@standard3d.com
// https://www.shadertoy.com/view/ltB3zD
float gold_noise(in vec2 xy, in float seed)
{
    return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);
}


#ifdef PIXEL

void effect() {
    //Extract Agent and Floor data from texture for this data block
    vec2 thisblock = VaryingTexCoord.xy;

    vec4 agent = Texel(AgentTex, thisblock);
        float heading = agent.z;
        vec2 pos = agent.xy;

    /* SENSE
        - The agent is in one of two states: foraging or returning home
        - State is flipped when the agent picks up resource
        - When in the foraging state the agent looks for
    */
    vec3 sensors = sense_trail(heading, FloorTex, thisblock);
    // 1.1 determine which heading from sensor data
    float sensL = sensors.x;
    float sensF = sensors.y;
    float sensR = sensors.z;

    if ((sensF < sensL) && (sensF < sensR)) {
        // turn randomly
        heading = gold_noise(thisblock, uTime)>0.5? mod(heading+pTurningAngle, TAU): mod(heading-pTurningAngle, TAU);
    }
    else if (sensL > sensF) {
        // turn left a bit
        heading = mod(heading+pTurningAngle, TAU);
    }
    else if (sensR > sensF) {
        // turn right
        heading = mod(heading-pTurningAngle, TAU);
    } else {
        // continue on current heading
    }

    //2. compute new position and heading based on previous data...
    vec2 dloc = pMoveSpeed/dt * vec2(cos(heading), sin(heading));
    pos += dloc;
    pos = vec2(mod(pos.x,ww), mod(pos.y,hh));

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
