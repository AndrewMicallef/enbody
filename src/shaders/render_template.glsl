/*
RENDERING SHADER TEMPLATE

MainTex is assumed to be the Particles.pos image

send data required:

DataTex -- Particles.dat image
CamRotation -- the rotation angle of camera along the Z axis

this template uses the dual curley braces pattern {{X}} for replacements.
The following replacements are required to be made in this template:

dim -- (integer) dimension of the position and data image
rotate_frag -- (shader code) fragment of shader code to affect rotation
ntypes -- (integer) the number of particle types in this universe

*/


uniform Image MainTex;
uniform Image DataTex;
uniform float CamRotation;
const int dim = {{dim}};

vec2 rotate(vec2 v, float t) {
	float s = sin(t);
	float c = cos(t);
	return vec2(
		c * v.x - s * v.y,
		s * v.x + c * v.y
	);
}

// function to get the integer type from the data vector
int getType(vec3 dat) {
    return int(floor(dat.y * {{ntypes}}));
}

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	vec2 uv = vertex_position.xy;
	vec3 pos = Texel(MainTex, uv).xyz;
	vec3 dat = Texel(DataTex, uv).xyz;
    int type = getType(dat);
    float mass = dat.x;

	//rotate with camera
	pos.xz = rotate(pos.xz, CamRotation);

	//perspective
		float near = -5000.0;
		float far = 5000.0;
		float depth = (pos.z - near) / (far - near);
		if (depth < 0.0) {
			//clip
			return vec4(0.0 / 0.0);
		} else {
			vertex_position.xy = pos.xy / mix(0.25, 2.0, depth);
		}


	// derive colour from type and mass
    // alpha is a function of depth

	VaryingColor.rgb = vec3(cos(dat.g), sin(dat.g), 1 - dat.g);
	VaryingColor.a = (1.0 - depth);

	//debug
	//VaryingColor = vec4(1.0);

	return transform_projection * vertex_position;

}
#endif

#ifdef PIXEL
void effect() {
	love_PixelColor = VaryingColor;
}
#endif
