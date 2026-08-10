import 'dart:async';

import 'package:review_calendar/features/records/data/record_categories_repository.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/records/data/memory_record_categories_repository.dart
final class MemoryRecordCategoriesRepository
    implements RecordCategoriesRepository {
  MemoryRecordCategoriesRepository({Iterable<String>? seed})
    : _categories = normalizeRecordCategories(seed ?? defaultRecordCategories);

  List<String> _categories;
  final StreamController<List<String>> _changes =
      StreamController<List<String>>.broadcast(sync: true);

  @override
  Stream<List<String>> watch() => Stream.multi((controller) {
    controller.add(_categories);
    final subscription = _changes.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> save(List<String> categories) async {
    _categories = normalizeRecordCategories(categories);
    if (!_changes.isClosed) {
      _changes.add(_categories);
    }
  }

  @override
  Future<void> dispose() => _changes.close();
}
