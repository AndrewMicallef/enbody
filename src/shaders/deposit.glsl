#pragma language glsl3
/*

*/
uniform Image AgentTex;    // The main texture on the mesh

const float pDepositVal = 1.0;


#ifdef PIXEL
void effect() {
    love_PixelColor = VaryingColor;
}
#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    vec2 xy = vertex_position.xy;
    vec2 pos = Texel(AgentTex, xy).xy;

    vertex_position.xy = pos.xy;

    VaryingColor.r += pDepositVal;
    VaryingColor.gba = vec3(0, 0,1.0);

    return transform_projection * vertex_position;
}
#endif
