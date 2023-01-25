#version 450

layout(push_constant) uniform Push
{
  vec4 OutputSize;
  vec4 OriginalSize;
  vec4 SourceSize;
	uint FrameCount;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
} global;

/*
 * sharp-shimmerless
 * Author: zadpos
 * License: Public domain
 * 
 * A retro gaming shader for sharpest pixels with no aliasing/shimmering.
 * Instead of pixels as point samples, this shader considers pixels as
 * ideal rectangles forming a grid, and interpolates pixel by calculating
 * the surface area an input pixel would occupy on an output pixel.
 */

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
    vec2 pixel = vTexCoord * params.OutputSize.xy * params.SourceSize.xy / params.OriginalSize.xy;
    vec2 pixel_floored = floor(pixel);
    vec2 pixel_ceiled = ceil(pixel);
    vec2 scale = params.OutputSize.xy / params.SourceSize.xy;
    vec2 invscale = params.SourceSize.xy / params.OutputSize.xy;
    vec2 texel_floored = floor(invscale * pixel_floored);
    vec2 texel_ceiled = floor(invscale * pixel_ceiled);

    vec2 mod_texel;

    if (texel_floored.x == texel_ceiled.x) {
        // The square-pixel lies "completely in" a single column of square-texel
        mod_texel.x = texel_ceiled.x + 0.5;
    } else {
        // The square-pixel lies across two neighboring columns and must be interpolated
        mod_texel.x = texel_ceiled.x + 0.5 - (scale.x * texel_ceiled.x - pixel_floored.x);
    }

    if (texel_floored.y == texel_ceiled.y) {
        // The square-pixel lies "completely in" a single row of square-texel
        mod_texel.y = texel_ceiled.y + 0.5;   
    } else {
        // The square-pixel lies across two neighboring rows and must be interpolated
        mod_texel.y = texel_ceiled.y + 0.5 - (scale.y * texel_ceiled.y - pixel_floored.y);
    }

   //vec2 texel = vTexCoord * params.SourceSize.xy;
   //mod_texel = texel;

   FragColor = vec4(texture(Source, mod_texel / params.SourceSize.xy).rgb, 1.0);
} 
