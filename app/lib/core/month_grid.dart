/// Shared 6x7 month-grid projection — mirrors `buildMonthGrid` in
/// screen-calendar.jsx. Used by the Calendar screen's month view and by the
/// Upload flow's period-picker (WindowEditSheet), so both render the exact
/// same grid shape.
class MonthCell {
  const MonthCell(this.date, this.outside);
  final DateTime date;
  final bool outside;
}

List<MonthCell> buildMonthGrid(int year, int month) {
  final first = DateTime(year, month, 1);
  final startDow = first.weekday % 7; // Sunday = 0
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final prevDays = DateTime(year, month, 0).day;

  final cells = <MonthCell>[];
  for (var i = 0; i < startDow; i++) {
    cells.add(
      MonthCell(DateTime(year, month - 1, prevDays - startDow + 1 + i), true),
    );
  }
  for (var d = 1; d <= daysInMonth; d++) {
    cells.add(MonthCell(DateTime(year, month, d), false));
  }
  while (cells.length < 42) {
    final next = cells.last.date.add(const Duration(days: 1));
    cells.add(MonthCell(next, true));
  }
  return cells;
}
