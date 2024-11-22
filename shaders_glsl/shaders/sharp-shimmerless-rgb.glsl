/*
 * sharp-shimmerless-vrgb
 * Author: zadpos
 * License: Public domain
 * 
 * Sharp-Shimmerless shader for v-RGB subpixels
 */

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
COMPAT_VARYING vec4 pixel;
COMPAT_VARYING vec4 scale;
COMPAT_VARYING vec4 invscale;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;

    vec2 pixel_xy = TexCoord.xy * OutputSize * TextureSize / InputSize;
    vec2 scale_xy = OutputSize / InputSize;
    vec2 invscale_xy = InputSize / OutputSize;
    
    pixel = pixel_xy.xxxy;
    scale = scale_xy.xxxy;
    invscale = invscale_xy.xxxy;
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
COMPAT_VARYING vec4 pixel;
COMPAT_VARYING vec4 scale;
COMPAT_VARYING vec4 invscale;

void main()
{
    vec4 pixel_floored = floor(pixel);
    pixel_floored.y -= 0.33;
    pixel_floored.w += 0.33;
    vec4 pixel_ceiled = ceil(pixel);
    pixel_ceiled.y -= 0.33;
    pixel_ceiled.w += 0.33;

    vec4 texel_floored = floor(invscale * pixel_floored);
    vec4 texel_ceiled = floor(invscale * pixel_ceiled);

    vec4 mod_texel;

    mod_texel = texel_ceiled + 0.5 - scale * texel_ceiled + pixel_floored;
    mod_texel = mix(mod_texel, texel_ceiled + 0.5, step(texel_ceiled, texel_floored));

    FragColor.r = COMPAT_TEXTURE(Texture, mod_texel.xw / TextureSize).r;
    FragColor.g = COMPAT_TEXTURE(Texture, mod_texel.yw / TextureSize).g;
    FragColor.b = COMPAT_TEXTURE(Texture, mod_texel.zw / TextureSize).b;
    FragColor.a = 1.0;
} 
#endif
