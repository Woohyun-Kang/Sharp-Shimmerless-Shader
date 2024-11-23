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

#pragma parameter CURVATURE "Curvature" 0.1 0.0 1.00 0.01

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec2 radial;
COMPAT_VARYING vec2 scale;
COMPAT_VARYING vec2 invscale;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;

    radial = TexCoord.xy * TextureSize / InputSize - vec2(0.5, 0.5);
    radial.x *= OutputSize.x / OutputSize.y;

    scale = OutputSize / InputSize;
    invscale = InputSize / OutputSize;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec2 radial;
COMPAT_VARYING vec2 scale; // pixel to texel scale
COMPAT_VARYING vec2 invscale;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float CURVATURE;
#else
#define CURVATURE 0.1
#endif

void main()
{
    vec2 fragRadial = radial;
    fragRadial *= 1.0 + CURVATURE * (dot(fragRadial, fragRadial) - 0.25);
    fragRadial.x /= OutputSize.x / OutputSize.y;
    fragRadial += vec2(0.5, 0.5);

    vec2 pixel = fragRadial * OutputSize;

    // pixel: output screen pixels
    // texel: input texels == game pixels
    vec2 pixel_tl = pixel - vec2(0.5, 0.5); // top-left of the pixel
    vec2 pixel_br = pixel + vec2(0.5, 0.5); // bottom-right of the pixel
    vec2 texel_tl = floor(invscale * pixel_tl); // texel the top-left of the pixel lies in
    vec2 texel_br = floor(invscale * pixel_br); // texel the bottom-right of the pixel lies in

    // the sampling point to get the correct box-filtered value
    vec2 mod_texel = texel_br + vec2(0.5, 0.5);
    mod_texel -= (vec2(1.0, 1.0) - step(texel_br, texel_tl)) * (scale * texel_br - pixel_tl);
    
    // smooth out the border and prevent garbage from out of bounds
    vec2 border_factor = clamp(pixel, 0.0, 1.0) * clamp(OutputSize - pixel, 0.0, 1.0);
    float factor = border_factor.x * border_factor.y;

    FragColor = vec4(factor * COMPAT_TEXTURE(Texture, mod_texel / TextureSize).rgb, 1.0);
} 
#endif
