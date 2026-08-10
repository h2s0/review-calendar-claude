final class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError.value(toString(), 'date', 'must be a valid date');
    }
  }

  factory LocalDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Date must use YYYY-MM-DD.', value);
    }
    return LocalDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final int year;
  final int month;
  final int day;

  @override
  int compareTo(LocalDate other) {
    final yearComparison = year.compareTo(other.year);
    if (yearComparison != 0) {
      return yearComparison;
    }
    final monthComparison = month.compareTo(other.month);
    if (monthComparison != 0) {
      return monthComparison;
    }
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDate &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() {
    final monthText = month.toString().padLeft(2, '0');
    final dayText = day.toString().padLeft(2, '0');
    return '$year-$monthText-$dayText';
  }
}

LocalDate localDateAtOffset(DateTime instant, Duration utcOffset) {
  final shifted = instant.toUtc().add(utcOffset);
  return LocalDate(shifted.year, shifted.month, shifted.day);
}
