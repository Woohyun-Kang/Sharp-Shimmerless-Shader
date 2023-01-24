# Sharp-Shimmerless-Shader

## A Sharp, Shimmering-free Shader for RetroArch
The Sharp-Shimmerless shader is a shader which guarantees minimum number of interpolated pixels, i.e., the sharpest pixels possible, while inducing NO shimmering.

## Existing Solution and Its Limitation
There already exist [sharp-bilinear shaders](https://github.com/rsn8887/Sharp-Bilinear-Shaders) to achive sharp pixels, but while they produced reasonably good image on modern high resolution screens, they fall apart on low-resolution screens often found in open-source handhelds.

Below is Cave Story, a 240p game, played on a 320p screen.

<table align=center>
  <thead>
    <tr>
      <th width="34%"></th>
      <th width="32%"></th>
      <th width="34%"></th>
    </tr>
  </thead>
 <tbody>
  <tr>
   <td colspan=3><video src="https://user-images.githubusercontent.com/82881609/214218505-dbb13ff4-fc8d-4621-b225-8309bb418c5c.mp4"></td>
  </tr>
  <tr align=center>
   <td> Sharp-Bilinear </td>
   <td> Sharp-Shimmerless </td>
   <td> Sharp-Bilinear-2x-Prescale </td>
  </tr>
 </tbody>
</table>

Sharp-Bilinear shader on the left side results in a very blurry image.
It is an expected behavior, since what sharp-bilinear shader does is integer pre-scaling followed by bilinear upscaling to screen - when scaling factor is less than 2, integer prescaling would do nothing.
Sharp-Bilinear shader becomes a regular **bilinear filter**.

Sharp-Bilinear-*2x-Prescale* shader on the right side, at first glance, produces a nice-looking, sharp image.
However, when the screen starts to scroll, you can notice vertical lines on the wall are **badly shimmering**.
(Shimmering is also there on Sharp-Bilinear shader, but less noticeable due to the *blurriness*.)

This is a fundamental limitation of bilinear interpolation, where each pixel is treated as a point, having location but no area.

## Interpolating Pixels as Rectangles
Sharp-Shimmerless shader abandons the idea of bilinear filtering, and instead treats input and output pixels as rectangles, occupying its area on screen.

It interpolates pixels based on how much area an input pixel would occupy on an output pixel.
* If the output pixel lies entirely on a single input pixel, there is no interpolation for the pixel
* If the output pixel lies across multiple input pixels, the input pixels are interpolated by the area they occupy on the output pixel.

Hence, it achieves minimal number of interpolated pixels while inducing **NO SHIMMERING**!
