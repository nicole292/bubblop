#version 460 core

// Candy ball and shell bubble. Rendered ONCE per colour and size into sprite
// images (see lib/render/orb_sprites.dart), never per frame.
//
// One light, top-left. Screen y points down.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // sprite size in pixels
uniform float uRadius;  // ball radius in pixels
uniform vec3 uColor;    // base colour, 0..1
uniform float uMode;    // 0 = glossy ball, 1 = white shell bubble

out vec4 fragColor;

void main() {
  vec2 p = (FlutterFragCoord().xy - uSize * 0.5) / uRadius;
  float d = length(p);
  float mask = 1.0 - smoothstep(1.0 - 1.5 / uRadius, 1.0, d);
  if (mask <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  float z = sqrt(max(0.0, 1.0 - d * d));
  vec3 n = normalize(vec3(p, z));
  vec3 L = normalize(vec3(-0.5, -0.7, 0.55));
  vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
  float lit = dot(n, L);

  // Soft highlight: a tilted oval near the top-left, plus a crisp hot spot.
  vec2 h = p - vec2(-0.32, -0.40);
  float ca = cos(0.6), sa = sin(0.6);
  h = vec2(ca * h.x + sa * h.y, -sa * h.x + ca * h.y);
  float shine = 1.0 - smoothstep(0.45, 1.0, length(vec2(h.x / 0.30, h.y / 0.18)));
  float spot = pow(max(dot(n, H), 0.0), 160.0);

  // How far toward the lower-right edge we are (the shaded side).
  float shadeSide = clamp(0.5 + 0.5 * (p.x + p.y) / 1.4, 0.0, 1.0);
  float edge = smoothstep(0.70, 1.0, d);

  if (uMode < 0.5) {
    vec3 base = uColor;
    vec3 light = mix(base, vec3(1.0), 0.22);
    vec3 dark = base * 0.68;

    vec3 col = mix(dark, light, smoothstep(-0.35, 0.95, lit));
    // Rich, slightly deeper colour toward the shaded rim.
    col = mix(col, dark * 0.9, edge * shadeSide * 0.55);
    // Light bounced up from the white board onto the lower rim.
    col += vec3(1.0) * 0.16 * edge * smoothstep(0.25, 0.95, p.y);
    col = mix(col, vec3(1.0), shine * 0.78);
    col += vec3(1.0) * spot * 0.6;
    // A whisper of contour so balls never merge into each other.
    col *= mix(1.0, 0.86, smoothstep(0.95, 1.0, d));

    fragColor = vec4(clamp(col, 0.0, 1.0) * mask, mask);
  } else {
    // White bubble: clear in the middle, solid toward the rim.
    vec3 col = mix(vec3(1.0), vec3(0.80, 0.83, 0.97), edge * shadeSide);
    float a = 0.14 + 0.5 * pow(d, 5.0);
    float ring = smoothstep(0.80, 0.86, d);
    a = max(a, ring * 0.95);
    col = mix(col, vec3(1.0), shine);
    a = max(a, shine * 0.9);
    a = clamp(a + spot * 0.6, 0.0, 1.0) * mask;
    fragColor = vec4(col * a, a);
  }
}
