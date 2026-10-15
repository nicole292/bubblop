#version 460 core

// Glass orb / frosted casing material. Rendered ONCE per colour and size into
// sprite images (see lib/render/orb_sprites.dart), never per frame.
//
// One light source, top-left. Screen y points down.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // sprite size in pixels
uniform float uRadius;  // orb radius in pixels
uniform vec3 uColor;    // base colour, 0..1
uniform float uMode;    // 0 = coloured glass orb, 1 = frosted shell casing,
                        // 2 = orb without its window reflection (a shell's core)

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = (frag - uSize * 0.5) / uRadius;
  float d = length(p);
  float aa = 1.5 / uRadius;
  float mask = 1.0 - smoothstep(1.0 - aa, 1.0, d);
  if (mask <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  float z = sqrt(max(0.0, 1.0 - d * d));
  vec3 n = normalize(vec3(p, z));
  vec3 L = normalize(vec3(-0.45, -0.65, 0.62));
  vec3 V = vec3(0.0, 0.0, 1.0);
  vec3 H = normalize(L + V);
  vec3 R = reflect(-V, n);
  float fres = pow(1.0 - z, 2.4);

  // What the glass reflects: a cool night sky above, the dark board below.
  vec3 sky = mix(vec3(0.06, 0.07, 0.16), vec3(0.42, 0.50, 0.92), smoothstep(0.1, 0.9, -R.y));
  // Reflections of the light: a soft oval hot spot plus a thin crescent of
  // light running along the upper-left rim.
  vec2 wq = p - vec2(-0.36, -0.44);
  float ca = cos(0.7), sa = sin(0.7);
  wq = vec2(ca * wq.x + sa * wq.y, -sa * wq.x + ca * wq.y);
  float spot = 1.0 - smoothstep(0.55, 1.0, length(vec2(wq.x / 0.20, wq.y / 0.11)));
  float crescent = (1.0 - smoothstep(0.86, 0.93, d))
      * smoothstep(0.80, 0.94, length(p - vec2(0.10, 0.13)))
      * clamp((-(p.x + p.y) - 0.05) / 0.9, 0.0, 1.0);
  float window = max(spot * 0.95, crescent * 0.6);
  float spec = pow(max(dot(n, H), 0.0), 140.0);
  float sheen = pow(max(dot(n, H), 0.0), 10.0);

  if (uMode < 0.5 || uMode > 1.5) {
    if (uMode > 1.5) window = 0.0;
    vec3 base = uColor;
    vec3 deep = base * base * 0.42;               // thick glass at the edge: darker, richer
    vec3 bright = min(base * 1.35 + 0.06, vec3(1.0));

    // Body: thin (light, clear) in the middle, thick (deep) at the edge.
    vec3 col = mix(deep, base, smoothstep(0.0, 0.85, z));

    // Light passing through the glass gathers at the lower right (caustic).
    vec2 c = vec2(0.30, 0.40);
    float caustic = exp(-dot(p - c, p - c) * 3.4);
    col += bright * caustic * 0.6;
    // A soft inner core of light.
    col += base * 0.22 * exp(-d * d * 2.2);

    // Gentle shaping from the key light.
    col *= 0.66 + 0.48 * max(dot(n, L), 0.0);

    // Environment reflection, strongest at grazing angles.
    col = mix(col, sky, fres * 0.35);
    col += vec3(0.85, 0.9, 1.0) * sheen * 0.10;

    // Bounce light from the lit floor along the lower rim.
    col += bright * smoothstep(0.45, 1.0, p.y) * fres * 0.9;

    // Reflected window and a crisp hot spot.
    col += vec3(1.0) * window * 0.8;
    col += vec3(1.0) * spec * 1.6;

    // Thin dark contour so stacked orbs stay separate.
    col *= mix(1.0, 0.45, smoothstep(0.94, 1.0, d));

    fragColor = vec4(col * mask, mask);
  } else {
    // Frosted casing: clear in the centre, milky and thick at the edge.
    float frost = noise(p * 8.0) * 0.6 + noise(p * 21.0 + 7.0) * 0.4;
    float edge = smoothstep(0.30, 0.95, d);
    float a = 0.04 + 0.50 * fres + 0.14 * frost * edge;
    vec3 col = vec3(0.86, 0.91, 1.0) * (0.92 + 0.08 * frost);

    // Casing thickness: a bright inner ring where light runs along the glass.
    float ring = smoothstep(0.80, 0.90, d) * (1.0 - smoothstep(0.90, 0.99, d));
    col += vec3(0.85, 0.90, 1.0) * ring * 0.6;
    a += ring * 0.35;

    col = mix(col, sky, 0.25);
    col += vec3(1.0) * (window * 1.0 + spec * 1.6);
    a += window * 0.75 + spec;

    // Shadowed lower-right lip of the casing.
    float lip = smoothstep(0.6, 1.0, d) * smoothstep(-0.2, 0.8, p.x + p.y);
    col *= 1.0 - lip * 0.25;

    a = clamp(a, 0.0, 1.0) * mask;
    fragColor = vec4(col * a, a);
  }
}
