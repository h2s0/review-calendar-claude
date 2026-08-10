import 'package:review_calendar/features/campaign/domain/local_date.dart';
import 'package:review_calendar/features/campaign/domain/local_time.dart';

sealed class VisitAvailability {
  const VisitAvailability();
}

final class VisitDateOptions extends VisitAvailability {
  factory VisitDateOptions(Iterable<LocalDate> values) {
    final dates = values.toSet().toList()..sort();
    if (dates.isEmpty) {
      throw ArgumentError.value(values, 'dates', 'must not be empty');
    }
    return VisitDateOptions._(List.unmodifiable(dates));
  }

  const VisitDateOptions._(this.dates);

  final List<LocalDate> dates;
}

final class VisitDateRange extends VisitAvailability {
  VisitDateRange({required this.start, required this.end}) {
    if (end.compareTo(start) < 0) {
      throw ArgumentError('Visit range end must not precede start.');
    }
  }

  final LocalDate start;
  final LocalDate end;
}

final class VisitTimeRange {
  VisitTimeRange({required this.start, required this.end}) {
    if (end.compareTo(start) < 0) {
      throw ArgumentError('Visit time end must not precede start.');
    }
  }

  final LocalTime start;
  final LocalTime end;
}

final class VisitSchedule {
  const VisitSchedule({this.date, this.time});

  final LocalDate? date;
  final LocalTime? time;
}
