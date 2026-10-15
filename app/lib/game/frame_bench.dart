import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Collects real frame timings from the engine (build = UI thread,
/// raster = GPU thread) and reports percentiles. Only meaningful in a
/// profile or release build; debug builds are much slower.
class FrameBench {
  final _build = <double>[];
  final _raster = <double>[];
  int peakEffects = 0;
  int pops = 0;

  void start() => SchedulerBinding.instance.addTimingsCallback(_onTimings);

  void stop() => SchedulerBinding.instance.removeTimingsCallback(_onTimings);

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _build.add(t.buildDuration.inMicroseconds / 1000);
      _raster.add(t.rasterDuration.inMicroseconds / 1000);
    }
  }

  String report() {
    String stats(String name, List<double> xs) {
      if (xs.isEmpty) return '$name: no frames';
      final s = [...xs]..sort();
      double pct(double p) => s[math.min(s.length - 1, (p * s.length).floor())];
      final avg = s.reduce((a, b) => a + b) / s.length;
      final over = s.where((x) => x > 16.7).length;
      return '$name ms: avg ${avg.toStringAsFixed(2)}  p50 ${pct(0.5).toStringAsFixed(2)}  '
          'p90 ${pct(0.9).toStringAsFixed(2)}  p99 ${pct(0.99).toStringAsFixed(2)}  '
          'max ${s.last.toStringAsFixed(2)}  >16.7ms: $over';
    }

    return [
      'FRAME BENCH (${kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'DEBUG - not representative'})',
      'frames: ${_build.length}, chain steps popped: $pops, peak active effects: $peakEffects',
      stats('build ', _build),
      stats('raster', _raster),
    ].join('\n');
  }
}
