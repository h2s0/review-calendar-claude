import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:review_calendar/features/records/data/record_categories_repository.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/records/data/firestore_record_categories_repository.dart
final class FirestoreRecordCategoriesRepository
    implements RecordCategoriesRepository {
  FirestoreRecordCategoriesRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _reference = firestore
           .collection('users')
           .doc(userId)
           .collection('preferences')
           .doc('recordCategories');

  final DocumentReference<Map<String, dynamic>> _reference;

  @override
  Stream<List<String>> watch() => _reference.snapshots().map((snapshot) {
    final raw = snapshot.data()?['categories'];
    if (raw is! List) {
      return defaultRecordCategories;
    }
    final categories = normalizeRecordCategories(raw.whereType<String>());
    return categories.isEmpty ? defaultRecordCategories : categories;
  });

  @override
  Future<void> save(List<String> categories) {
    final normalized = normalizeRecordCategories(categories);
    return _reference.set({
      'categories': normalized.isEmpty ? defaultRecordCategories : normalized,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> dispose() async {}
}
