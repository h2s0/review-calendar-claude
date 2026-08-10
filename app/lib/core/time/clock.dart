/// Ported verbatim from review-calendar/app/lib/core/time/clock.dart
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
