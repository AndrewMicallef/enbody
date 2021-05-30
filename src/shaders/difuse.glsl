#pragma language glsl3
/*

*/
uniform Image FloorTex;    // The Data 8bit image [trial, X,X]

#ifdef PIXEL

void effect() {
    vec2 xy = VaryingTexCoord.xy;
    vec4 floor = Texel(FloorTex, xy);

    // diffuse
    float trail_sum = 0.0;

    // apply a mean filter
    for (int dX = -1; dX <= 1; dX++){
        for (int dY = -1; dY <= 1; dY++){
            // https://stackoverflow.com/questions/33270823/how-to-cast-int-to-float-in-glsl-webgl
            vec2 offset = vec2(float(dX), float(dY));
            trail_sum += Texel(FloorTex, xy+offset).x;
        }
    }

    trail_sum /= 9;
    floor.x = trail_sum;

    love_PixelColor = floor;
}


#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
