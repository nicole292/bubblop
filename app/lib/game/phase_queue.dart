import 'dart:collection';

/// One timed animation step. [onUpdate] receives progress from 0 to 1.
class Phase {
  Phase(this.duration, {this.onStart, this.onUpdate, this.onEnd});

  final double duration;
  final void Function()? onStart;
  final void Function(double t)? onUpdate;
  final void Function()? onEnd;
}

/// Plays [Phase]s one after another. Speeding up only changes how fast time
/// passes; every phase still starts and ends, so the picture always ends up
/// matching the rules.
class PhaseQueue {
  final _pending = Queue<Phase>();
  Phase? _current;
  double _elapsed = 0;

  /// Time multiplier. Resets to 1 whenever the queue runs empty.
  double speed = 1;

  bool get isIdle => _current == null && _pending.isEmpty;

  void addAll(Iterable<Phase> phases) => _pending.addAll(phases);

  void update(double dt) {
    var budget = dt * speed;
    while (true) {
      if (_current == null) {
        if (_pending.isEmpty) {
          speed = 1;
          return;
        }
        _current = _pending.removeFirst();
        _elapsed = 0;
        _current!.onStart?.call();
      }
      final phase = _current!;
      final left = phase.duration - _elapsed;
      if (budget < left) {
        _elapsed += budget;
        phase.onUpdate?.call(_elapsed / phase.duration);
        return;
      }
      budget -= left;
      phase.onUpdate?.call(1);
      phase.onEnd?.call();
      _current = null;
    }
  }

  /// Drops everything without running it (used when restarting).
  void clear() {
    _pending.clear();
    _current = null;
    speed = 1;
  }
}
