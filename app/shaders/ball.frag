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

  // Soft highlight: a tilted oval near the top-left, plus a tiny glint.
  vec2 h = p - vec2(-0.30, -0.42);
  float ca = cos(0.6), sa = sin(0.6);
  h = vec2(ca * h.x + sa * h.y, -sa * h.x + ca * h.y);
  float shine = 1.0 - smoothstep(0.25, 1.0, length(vec2(h.x / 0.30, h.y / 0.17)));
  float spot = pow(max(dot(n, H), 0.0), 220.0);

  float edge = smoothstep(0.72, 1.0, d);

  if (uMode < 0.5) {
    // Mostly the ball's own solid colour: gentle shading, no heavy gloss.
    vec3 base = uColor;
    vec3 light = mix(base, vec3(1.0), 0.16);
    vec3 dark = base * 0.80;

    vec3 col = mix(dark, light, smoothstep(-0.45, 0.95, lit));
    // Light bounced up from the white board onto the lower rim.
    col += vec3(1.0) * 0.10 * edge * smoothstep(0.3, 0.95, p.y);
    col = mix(col, vec3(1.0), shine * 0.55);
    col += vec3(1.0) * spot * 0.30;
    // A whisper of contour so balls never merge into each other.
    col *= mix(1.0, 0.88, smoothstep(0.93, 1.0, d));

    fragColor = vec4(clamp(col, 0.0, 1.0) * mask, mask);
  } else {
    // Shell: frosted white glass over a full-size ball, with a clean rim.
    float a = 0.46 + 0.30 * smoothstep(0.55, 1.0, d);
    float ring = smoothstep(0.83, 0.88, d);
    a = mix(a, 0.96, ring);
    a = max(a, shine * 0.85);
    a = clamp(a + spot * 0.4, 0.0, 1.0) * mask;
    vec3 col = mix(vec3(1.0), vec3(0.90, 0.92, 1.0), edge * (1.0 - ring));
    fragColor = vec4(col * a, a);
  }
}
