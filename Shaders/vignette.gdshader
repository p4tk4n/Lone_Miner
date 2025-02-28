shader_type canvas_item;

void fragment() {
    vec2 uv = UV - vec2(0.5); // Center the UV coordinates
    float radius = 0.85; // Adjust vignette size
    float softness = 0.5; // Adjust for smooth transition

    float vignette = smoothstep(radius, radius - softness, length(uv));

    // Make the center fully transparent and edges darker
    COLOR = vec4(0.0, 0.0, 0.0, 1.0 - vignette);
}
