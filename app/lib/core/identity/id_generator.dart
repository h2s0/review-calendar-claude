import 'dart:math';

/// Ported verbatim from review-calendar/app/lib/core/identity/id_generator.dart
abstract interface class IdGenerator {
  String nextId();
}

class RandomIdGenerator implements IdGenerator {
  RandomIdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String nextId() {
    return List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      growable: false,
    ).join();
  }
}
