final class CampaignId {
  CampaignId(String value) : value = _requireValue(value, 'campaign ID');

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CampaignId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class UserId {
  UserId(String value) : value = _requireValue(value, 'user ID');

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

String _requireValue(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be empty');
  }
  return normalized;
}
