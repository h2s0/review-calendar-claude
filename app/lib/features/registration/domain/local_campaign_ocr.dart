import 'package:review_calendar/features/records/data/record_categories_repository.dart';
import 'package:review_calendar/features/registration/domain/campaign_analysis.dart';
import 'package:review_calendar/features/registration/domain/campaign_registration_draft.dart';
import 'package:review_calendar/features/registration/domain/registration_image.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/registration/domain/local_campaign_ocr.dart
/// — fully on-device (Vision OCR text + regex field extraction), no server
/// round-trip. This project uses this path exclusively (see
/// `CampaignAnalysisViewModel` in the sibling, which also treats the local
/// service as an optional override of its remote Cloud Function path).
abstract interface class CampaignOcrEngine {
  Future<String> recognize(RegistrationImage image);
}

abstract interface class LocalCampaignAnalysisService {
  Future<CampaignAnalysisResult> analyze(List<RegistrationImage> images);
}

final class OcrCampaignAnalysisService implements LocalCampaignAnalysisService {
  const OcrCampaignAnalysisService(this._engine);

  final CampaignOcrEngine _engine;

  @override
  Future<CampaignAnalysisResult> analyze(List<RegistrationImage> images) async {
    final texts = <String>[];
    for (final image in images) {
      final text = (await _engine.recognize(image)).trim();
      if (text.isNotEmpty) texts.add(text);
    }
    if (texts.isEmpty) {
      throw const CampaignAnalysisException(
        CampaignAnalysisFailure.invalidResponse,
      );
    }
    return parseCampaignOcrText(texts.join('\n'));
  }
}

CampaignAnalysisResult parseCampaignOcrText(String rawText) {
  final lines = rawText
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final normalized = lines.join('\n');
  final inferredYear = int.tryParse(
    RegExp(r'(20\d{2})년').firstMatch(normalized)?.group(1) ?? '',
  );
  // ".lastOrNull" rather than the visit-window's ".first": a single "마감"
  // label always has just one date, but "등록기간"-style labels give a
  // start~end registration window — the deadline that actually matters is
  // the window's last day, not its first.
  final deadline = _datesAfterLabel(
    lines,
    RegExp(r'리뷰\s*마감|포스팅\s*마감|제출\s*마감|업로드\s*마감|등록\s*기간'),
    inferredYear,
  ).lastOrNull;
  final visitDates = _datesAfterLabel(
    lines,
    RegExp(r'체험\s*기간|방문\s*기간|방문\s*가능(?!\s*시간)|체험\s*가능(?!\s*시간)'),
    inferredYear,
  );
  final phone = RegExp(
    r'(?<!\d)(01[016789])[-\s]?(\d{3,4})[-\s]?(\d{4})(?!\d)',
  ).firstMatch(normalized);
  final wonAmounts = RegExp(r'(?<!\d)(\d{1,3}(?:,\d{3})+|\d{4,})\s*원')
      .allMatches(normalized)
      .map((match) {
        return int.tryParse(match.group(1)!.replaceAll(',', ''));
      })
      .whereType<int>()
      .toList(growable: false);
  final tenThousandWonAmounts = RegExp(r'(?<!\d)(\d+(?:\.\d+)?)\s*만\s*원')
      .allMatches(normalized)
      .map((match) => double.tryParse(match.group(1)!))
      .whereType<double>()
      .map((amount) => (amount * 10000).round())
      .toList(growable: false);
  final amounts = [...wonAmounts, ...tenThousandWonAmounts];
  final amountNeedsReview =
      amounts.length != 1 ||
      !RegExp(r'제공\s*(?:금액|내역|혜택)|협찬|상당|원가').hasMatch(normalized);
  final brand = _brandCandidate(lines);
  final category = _categoryCandidate(normalized);
  final platform = _platformCandidate(lines);
  final availableTimes = _availableTimes(lines);

  return CampaignAnalysisResult(
    brand: brand == null
        ? const CampaignAnalysisField<String>()
        : CampaignAnalysisField<String>(
            value: brand.value,
            confidence: brand.confidence,
            needsReview: brand.needsReview,
          ),
    platform: _confirmedField(platform),
    category: _confirmedField(category),
    visitAvailability: visitDates.isEmpty
        ? const CampaignAnalysisField<CampaignAnalysisVisitAvailability>()
        : CampaignAnalysisField<CampaignAnalysisVisitAvailability>(
            value: CampaignAnalysisVisitAvailability(
              startDate: visitDates.first,
              endDate: visitDates.length > 1 ? visitDates.last : null,
            ),
            confidence: 0.9,
            needsReview: false,
          ),
    availableTimes: availableTimes.isEmpty
        ? const CampaignAnalysisField<List<VisitTimeRangeDraft>>()
        : CampaignAnalysisField<List<VisitTimeRangeDraft>>(
            value: availableTimes,
            confidence: 0.9,
            needsReview: false,
          ),
    deadline: _confirmedField(deadline),
    contactPhone: _confirmedField(
      phone == null
          ? null
          : '${phone.group(1)}-${phone.group(2)}-${phone.group(3)}',
    ),
    sponsoredValue: amounts.isEmpty
        ? const CampaignAnalysisField<int>()
        : CampaignAnalysisField<int>(
            value: amounts.reduce((left, right) => left > right ? left : right),
            confidence: 0.9,
            needsReview: amountNeedsReview,
          ),
    notes: CampaignAnalysisField<String>(
      value: normalized,
      confidence: 1,
      needsReview: false,
    ),
    rawDeadlineText: _confirmedField(deadline),
  );
}

CampaignAnalysisField<String> _confirmedField(String? value) {
  if (value == null || value.isEmpty) {
    return const CampaignAnalysisField<String>();
  }
  return CampaignAnalysisField<String>.confirmed(value, confidence: 0.9);
}

List<String> _datesAfterLabel(
  List<String> lines,
  RegExp label,
  int? inferredYear,
) {
  for (var index = 0; index < lines.length; index++) {
    if (!label.hasMatch(lines[index])) continue;
    for (final line in lines.skip(index).take(3)) {
      final dates = _dates(line, inferredYear);
      if (dates.isNotEmpty) return dates;
    }
  }
  return const [];
}

List<String> _dates(String text, int? inferredYear) {
  final results = <String>[];
  final yearDates = RegExp(
    r'(?:(20\d{2})[.\-/년]\s*)?(1[0-2]|0?[1-9])[.\-/월]\s*(3[01]|[12]\d|0?[1-9])(?:일)?',
  );
  for (final match in yearDates.allMatches(text)) {
    final year = match.group(1) ?? inferredYear?.toString();
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    results.add(
      year == null
          ? '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}'
          : '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );
  }
  return results;
}

_BrandCandidate? _brandCandidate(List<String> lines) {
  final labeled = RegExp(r'(?:업체|상호|브랜드|매장)\s*[:：]\s*(.+)');
  for (final line in lines) {
    final match = labeled.firstMatch(line);
    if (match != null) {
      return _BrandCandidate(
        match.group(1)!.trim(),
        confidence: 0.95,
        needsReview: false,
      );
    }
  }
  for (var index = 0; index < lines.length - 1; index++) {
    if (!RegExp(r'방문\s*주소').hasMatch(lines[index])) continue;
    final trailingName = RegExp(
      r'\d+(?:-\d+)?\s+(.+)$',
    ).firstMatch(lines[index + 1])?.group(1)?.trim();
    if (trailingName != null && trailingName.isNotEmpty) {
      return _BrandCandidate(trailingName, confidence: 0.8, needsReview: false);
    }
  }
  return _unlabeledBrandCandidate(lines);
}

/// Falls back to the first plausible-looking line near the top of the OCR
/// text when nothing was explicitly labeled — many real campaign
/// screenshots put the store/brand name as the very first line with no
/// "업체:" prefix. Always `needsReview: true` since it's a guess rather
/// than a confirmed match; the confirm screen lets the user correct it
/// either way, so a wrong guess costs no more than the blank field it
/// replaces.
_BrandCandidate? _unlabeledBrandCandidate(List<String> lines) {
  const platforms = {'블로그', '인스타그램', '유튜브', '틱톡'};
  final nonBrandLine = RegExp(
    r'방문\s*주소|방문\s*정보|방문\s*가능|방문\s*기간|체험\s*가능|체험\s*기간|'
    r'체험단\s*미션|담당자|리뷰\s*마감|포스팅\s*마감|제출\s*마감|업로드\s*마감|'
    r'카테고리|연락처',
  );
  final datePattern = RegExp(r'\d{1,4}[.\-/월년]\s*\d{1,2}');
  final phonePattern = RegExp(r'01[016789][-\s]?\d{3,4}[-\s]?\d{4}');
  final moneyOnlyLine = RegExp(r'^\d[\d,]*\s*원$|^\d+(?:\.\d+)?\s*만\s*원$');

  for (final line in lines.take(6)) {
    if (line.length < 2 || line.length > 40) continue;
    if (line.endsWith('?')) continue;
    if (platforms.contains(line)) continue;
    if (defaultRecordCategories.contains(line)) continue;
    if (nonBrandLine.hasMatch(line)) continue;
    if (datePattern.hasMatch(line)) continue;
    if (phonePattern.hasMatch(line)) continue;
    if (moneyOnlyLine.hasMatch(line)) continue;
    return _BrandCandidate(line, confidence: 0.5, needsReview: true);
  }
  return null;
}

final class _BrandCandidate {
  const _BrandCandidate(
    this.value, {
    required this.confidence,
    required this.needsReview,
  });

  final String value;
  final double confidence;
  final bool needsReview;
}

String? _categoryCandidate(String text) {
  const categories = defaultRecordCategories;
  for (final category in categories) {
    if (text.contains(category)) return category;
  }
  if (RegExp(r'사무실|오피스|공간').hasMatch(text)) return '생활';
  return null;
}

String? _platformCandidate(List<String> lines) {
  const platforms = ['블로그', '인스타그램', '유튜브', '틱톡'];
  for (var index = 0; index < lines.length; index++) {
    for (final platform in platforms) {
      if (lines[index] == platform) return platform;
      if (RegExp(r'체험단\s*미션').hasMatch(lines[index]) &&
          index + 1 < lines.length &&
          lines[index + 1].contains(platform)) {
        return platform;
      }
    }
  }
  return null;
}

List<VisitTimeRangeDraft> _availableTimes(List<String> lines) {
  final pattern = RegExp(
    r'(오전|오후)?\s*(\d{1,2})시(?:\s*(\d{1,2})분)?\s*[~～-]\s*'
    r'(오전|오후)?\s*(\d{1,2})시(?:\s*(\d{1,2})분)?',
  );
  for (final line in lines.where((line) => line.contains('시간'))) {
    final match = pattern.firstMatch(line);
    if (match == null) continue;
    String time(int meridiemIndex, int hourIndex, int minuteIndex) {
      var hour = int.parse(match.group(hourIndex)!);
      final meridiem = match.group(meridiemIndex);
      if (meridiem == '오후' && hour < 12) hour += 12;
      if (meridiem == '오전' && hour == 12) hour = 0;
      final minute = int.tryParse(match.group(minuteIndex) ?? '') ?? 0;
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    }

    return [VisitTimeRangeDraft(start: time(1, 2, 3), end: time(4, 5, 6))];
  }
  return const [];
}
