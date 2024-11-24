/*
 * sharp-shimmerless-gammacorrected
 * Author: zadpos
 * License: Public domain
 * 
 * A retro gaming shader for sharpest pixels with no aliasing/shimmering.
 * Instead of pixels as point samples, this shader considers pixels as
 * ideal rectangles forming a grid, and interpolates pixel by calculating
 * the surface area an input pixel would occupy on an output pixel.
 */

#pragma parameter GAMMA "Gamma" 2.2 0.0 1.00 0.05

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
COMPAT_VARYING vec2 pixel;
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
    pixel = TexCoord.xy * OutputSize * TextureSize / InputSize;
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
COMPAT_VARYING vec2 pixel; // texel to pixel scale
COMPAT_VARYING vec2 scale; // pixel to texel scale
COMPAT_VARYING vec2 invscale;

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float GAMMA;
#else
#define GAMMA 2.2
#endif

#define INV_GAMMA (1.0 / GAMMA)

void main()
{
    // pixel: output screen pixels
    // texel: input texels == game pixels
    vec2 pixel_tl = floor(pixel);   // top-left of the pixel
    vec2 pixel_br = ceil(pixel);    // bottom-right of the pixel
    vec2 texel_tl = floor(invscale * pixel_tl); // texel the top-left of the pixel lies in
    vec2 texel_br = floor(invscale * pixel_br); // texel the bottom-right of the pixel lies in
    vec2 texel_tr = vec2(texel_br.x, texel_tl.y);
    vec2 texel_bl = vec2(texel_tl.x, texel_br.y);

    vec3 color_tl = pow(COMPAT_TEXTURE(Texture, (texel_tl + vec2(0.5, 0.5)) / TextureSize).rgb, vec3(GAMMA, GAMMA, GAMMA));
    vec3 color_tr = pow(COMPAT_TEXTURE(Texture, (texel_tr + vec2(0.5, 0.5)) / TextureSize).rgb, vec3(GAMMA, GAMMA, GAMMA));
    vec3 color_bl = pow(COMPAT_TEXTURE(Texture, (texel_bl + vec2(0.5, 0.5)) / TextureSize).rgb, vec3(GAMMA, GAMMA, GAMMA));
    vec3 color_br = pow(COMPAT_TEXTURE(Texture, (texel_br + vec2(0.5, 0.5)) / TextureSize).rgb, vec3(GAMMA, GAMMA, GAMMA));

    vec2 interp_ratio = vec2(1.0, 1.0) - (vec2(1.0, 1.0) - step(texel_br, texel_tl)) * (scale * texel_br - pixel_tl);

    vec3 color = mix(mix(color_tl, color_tr, interp_ratio.x), mix(color_bl, color_br, interp_ratio.x), interp_ratio.y);
    color = pow(color, vec3(INV_GAMMA, INV_GAMMA, INV_GAMMA));
    
    FragColor = vec4(color, 1.0);
} 
#endif
