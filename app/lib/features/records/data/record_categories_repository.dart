/// Ported verbatim from
/// review-calendar/app/lib/features/records/data/record_categories_repository.dart
abstract interface class RecordCategoriesRepository {
  Stream<List<String>> watch();

  Future<void> save(List<String> categories);

  Future<void> dispose();
}

const defaultRecordCategories = ['맛집', '카페', '뷰티', '건강식품', '생활', '기타'];

List<String> normalizeRecordCategories(Iterable<String> categories) {
  final normalized = <String>{};
  for (final category in categories) {
    final value = category.trim();
    if (value.isNotEmpty && value != '전체') {
      normalized.add(value);
    }
  }
  return List.unmodifiable(normalized);
}
