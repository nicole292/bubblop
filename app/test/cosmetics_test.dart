import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_pop/progress/cosmetics.dart';
import 'package:project_pop/render/piece_shapes.dart';

/// CIELAB colour (perceived lightness and hue), for measuring how different
/// two colours look.
List<double> lab(Color c) {
  double lin(double v) => v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = lin(c.r), g = lin(c.g), b = lin(c.b);
  final x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
  final y = r * 0.2126 + g * 0.7152 + b * 0.0722;
  final z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;
  double f(double t) => t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

/// Perceived difference between two colours (ΔE 1976; ~2 is just visible).
double difference(Color a, Color b) {
  final p = lab(a), q = lab(b);
  return math.sqrt(math.pow(p[0] - q[0], 2) + math.pow(p[1] - q[1], 2) + math.pow(p[2] - q[2], 2));
}

void main() {
  final ballSets = Cosmetics.ofKind(CosmeticKind.balls);

  test('every ball set has five colours that are easy to tell apart', () {
    for (final set in ballSets) {
      expect(set.colors.length, 5, reason: set.name);
      for (var i = 0; i < 5; i++) {
        for (var j = i + 1; j < 5; j++) {
          expect(difference(set.colors[i], set.colors[j]), greaterThan(35),
              reason: '${set.name}: colours $i and $j look too alike');
        }
      }
    }
  });

  test('ball sets look clearly different from each other', () {
    for (var a = 0; a < ballSets.length; a++) {
      for (var b = a + 1; b < ballSets.length; b++) {
        var total = 0.0;
        for (var i = 0; i < 5; i++) {
          total += difference(ballSets[a].colors[i], ballSets[b].colors[i]);
        }
        expect(total / 5, greaterThan(22), reason: '${ballSets[a].name} and ${ballSets[b].name} look alike');
      }
    }
  });

  test('skies have three colours and stay light behind white text', () {
    for (final sky in Cosmetics.ofKind(CosmeticKind.sky)) {
      expect(sky.colors.length, 3, reason: sky.name);
      for (final c in sky.colors) {
        expect(lab(c)[0], inInclusiveRange(50, 85), reason: '${sky.name}: too dark or too pale');
      }
    }
  });

  test('every shape fills its cell without touching a neighbour', () {
    const r = 100.0;
    // Balls are 0.47 of a cell, so half a cell is 1.064 radii.
    for (final set in Cosmetics.ofKind(CosmeticKind.shape)) {
      expect(set.colors, isEmpty, reason: '${set.name}: shapes keep the chosen colours');
      final path = piecePath(set.shape, r);
      if (set.shape == PieceShape.ball) {
        expect(path, isNull);
        continue;
      }
      final bounds = path!.getBounds();
      expect(bounds.width, inInclusiveRange(r * 1.7, r * 2.12), reason: set.name);
      expect(bounds.height, inInclusiveRange(r * 1.7, r * 2.12), reason: set.name);
      for (final edge in [bounds.left, bounds.top, -bounds.right, -bounds.bottom]) {
        expect(edge, greaterThanOrEqualTo(-r * 1.064), reason: '${set.name} reaches into the next cell');
      }
      // The material is drawn out to shapeCover radii; the outline must stay inside it.
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 2) {
          expect(metric.getTangentForOffset(d)!.position.distance, lessThanOrEqualTo(r * shapeCover),
              reason: '${set.name} pokes out of its shading');
        }
      }
    }
  });

  test('ids are unique and every id can be looked up', () {
    final ids = Cosmetics.all.map((c) => c.id).toSet();
    expect(ids.length, Cosmetics.all.length);
    for (final c in Cosmetics.all) {
      expect(Cosmetics.byId(c.id), same(c));
    }
  });
}
