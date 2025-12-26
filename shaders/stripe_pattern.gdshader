// stripe_pattern.gdshader
// Adds horizontal white stripes to sprite based on UV coordinates
shader_type canvas_item;

// Stripe width (0.0-1.0, where 1.0 = full height)
uniform float stripe_width : hint_range(0.0, 1.0) = 0.15;

// Stripe spacing (number of stripes across sprite height)
uniform float stripe_count : hint_range(1.0, 20.0) = 5.0;

// Stripe color (default white)
uniform vec4 stripe_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Whether stripes are enabled (0.0 = off, 1.0 = on)
uniform float stripes_enabled : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Get the original texture color
	vec4 base_color = texture(TEXTURE, UV);
	
	// Calculate which stripe we're in based on Y coordinate
	float y_position = UV.y * stripe_count;
	float stripe_index = floor(y_position);
	
	// Get position within current stripe (0.0 to 1.0)
	float position_in_stripe = fract(y_position);
	
	// Determine if we're in a stripe region
	bool in_stripe = position_in_stripe < stripe_width;
	
	// Mix between base color and stripe color
	vec4 final_color = base_color;
	if (in_stripe && stripes_enabled > 0.5) {
		// Blend stripe color with base color (keeping alpha from base)
		final_color.rgb = mix(base_color.rgb, stripe_color.rgb, stripe_color.a);
	}
	
	COLOR = final_color;
}
