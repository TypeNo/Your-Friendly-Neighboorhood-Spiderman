shader_type canvas_item;

uniform float rotation_angle : hint_range(-360.0, 360.0); // in degrees

// Utility function to rotate UVs around a pivot
vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
    float rad = rotation * PI / 180.0;  // Convert to radians
    mat2 rotation_matrix = mat2(
        vec2(cos(rad), -sin(rad)),
        vec2(sin(rad),  cos(rad))
    );
    uv -= pivot;
    uv = rotation_matrix * uv;
    uv += pivot;
    return uv;
}

void fragment() {
    vec2 rotated_uv = rotateUV(UV, vec2(0.5), rotation_angle);
    COLOR = texture(TEXTURE, rotated_uv);
}
