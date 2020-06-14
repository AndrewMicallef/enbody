
local Base_Shader = {}



[[
uniform Image MainTex;
uniform float dt;

uniform float sampling_percent;
uniform float sampling_percent_offset;
#ifdef PIXEL

void effect() {
    love_PixelColor = vec4(acc, 1.0);
}
#endif

#ifdef VERTEX

vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    return transform_projection * vertex_position;
}

#endif
]]
