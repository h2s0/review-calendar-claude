const _weekdaysKo = ['일', '월', '화', '수', '목', '금', '토'];

String weekdayKo(DateTime date) => _weekdaysKo[date.weekday % 7];

/// `12,345` — matches the prototype's `Number.toLocaleString()`.
String formatNumber(int value) {
  final text = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
  }
  return (value < 0 ? '-' : '') + buffer.toString();
}

String formatWon(int amount) => '${formatNumber(amount)}원';

/// `"68000"` → `"6만 8000원"`, `"123000000"` → `"1억 2300만원"` — matches
/// the design prototype's `formatKoreanWon()`, shown live under the manual
/// 협찬/원고료 amount inputs in screen-upload.jsx.
String formatKoreanWon(String rawValue) {
  final n = int.tryParse(rawValue) ?? 0;
  if (n <= 0) return '';
  final eok = n ~/ 100000000;
  final man = (n % 100000000) ~/ 10000;
  final rest = n % 10000;
  final parts = <String>[
    if (eok > 0) '$eok억',
    if (man > 0) '$man만',
    if (rest > 0) formatNumber(rest),
  ];
  return '${parts.join(' ')}원';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String monthDayLabel(DateTime date) => '${date.month}월 ${date.day}일';

String shortDateLabel(DateTime date) =>
    '${date.month}/${date.day}(${weekdayKo(date)})';
