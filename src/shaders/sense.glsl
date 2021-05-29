/*

*/
uniform float uTime;             // Time in seconds (for use in seeding the random function)
uniform Image OrganismTex; // Image Data of the macro organism [self, outbound, inbound]
uniform Image AgentTex;    // The Agent data [locx, locy, heading, X]
uniform Image FloorTex;    // The Data 8bit image [trial, X,X]
//uniform float dt;

const float TAU = 6.28318530717958647692528; // 2*Pi
const float PHI = 1.61803398874989484820459; // Φ = Golden Ratio [gould random function]

const float pTurningAngle = TAU * 0.25;
const float pSenseRadius =  1 / min(textureSize(FloorTex).x, textureSize(FloorTex).y);
const float pSenseAngle = TAU * 0.15;
const float pMoveSpeed = 1 / min(textureSize(FloorTex).x, textureSize(FloorTex).y);

#ifdef PIXEL

void effect() {
    //Extract Agent and Floor data from texture for this data block
    vec2 thisblock = VaryingTexCoord.xy

    vec4 organism = Texel(OrganismTex, thisblock);
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

    if (sensF < sensL) && (sensF < sensR) {
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

    vec2 dloc = movespeed * vec2(cos(heading), sin(heading));
    pos += dloc

    //2. compute new position and heading based on previous data...


    // output new data
    love_PixelColor = vec4(pos.x, pos.y, heading, agent.w);
}

vec3 sense_trial(float heading, Image FloorTex, vec2 coordinates){

    vec2 offsetL = pSenseRadius * vec2(cos(heading-pSenseAngle), sin(heading-pSenseAngle));
    vec2 offsetF = pSenseRadius * vec2(cos(heading), sin(heading));
    vec2 offsetR = pSenseRadius * vec2(cos(heading+pSenseAngle), sin(heading+pSenseAngle));

    return vec3(
            texel(FloorTex, coordinates + offsetL).x,
            texel(FloorTex, coordinates + offsetF).x,
            texel(FloorTex, coordinates + offsetR).x,
        );
}


// Gold Noise ©2015 dcerisano@standard3d.com
// https://www.shadertoy.com/view/ltB3zD
float gold_noise(in vec2 xy, in float seed)
{
    return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);
}

#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
