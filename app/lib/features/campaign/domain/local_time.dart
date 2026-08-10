final class LocalTime implements Comparable<LocalTime> {
  LocalTime(this.hour, this.minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError.value(toString(), 'time', 'must be a valid time');
    }
  }

  factory LocalTime.parse(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Time must use HH:mm.', value);
    }
    return LocalTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  final int hour;
  final int minute;

  @override
  int compareTo(LocalTime other) {
    final hourComparison = hour.compareTo(other.hour);
    if (hourComparison != 0) {
      return hourComparison;
    }
    return minute.compareTo(other.minute);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTime && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() {
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }
}
