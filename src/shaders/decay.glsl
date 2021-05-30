#pragma language glsl3
/*

*/
uniform Image FloorTex;    // The Data 8bit image [trial, X,X]
uniform float dt;          // time since last tick
const float pDecayKonst = .15;

#ifdef PIXEL

void effect() {
    vec2 xy = VaryingTexCoord.xy;
    vec4 floor = Texel(FloorTex, xy);

    floor.x = floor.x * pDecayKonst / dt;

    love_PixelColor = floor;
}


#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
