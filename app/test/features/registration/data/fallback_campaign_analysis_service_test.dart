import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/registration/data/fallback_campaign_analysis_service.dart';
import 'package:review_calendar/features/registration/domain/campaign_analysis.dart';
import 'package:review_calendar/features/registration/domain/local_campaign_ocr.dart';
import 'package:review_calendar/features/registration/domain/registration_image.dart';

final class _StubService implements LocalCampaignAnalysisService {
  _StubService.returns(this._result) : _failure = null;
  _StubService.throws(CampaignAnalysisFailure failure)
    : _failure = failure,
      _result = null;

  final CampaignAnalysisResult? _result;
  final CampaignAnalysisFailure? _failure;
  int callCount = 0;

  @override
  Future<CampaignAnalysisResult> analyze(List<RegistrationImage> images) async {
    callCount++;
    final failure = _failure;
    if (failure != null) throw CampaignAnalysisException(failure);
    return _result!;
  }
}

List<RegistrationImage> _images() => const [];

void main() {
  test('returns the primary result without touching the fallback', () async {
    final primary = _StubService.returns(
      const CampaignAnalysisResult(
        brand: CampaignAnalysisField.confirmed('Gemini 결과'),
      ),
    );
    final fallback = _StubService.returns(
      const CampaignAnalysisResult(
        brand: CampaignAnalysisField.confirmed('OCR 결과'),
      ),
    );
    final service = FallbackCampaignAnalysisService(
      primary: primary,
      fallback: fallback,
    );

    final result = await service.analyze(_images());

    expect(result.brand.value, 'Gemini 결과');
    expect(primary.callCount, 1);
    expect(fallback.callCount, 0);
  });

  test('falls back to the on-device result when the primary throws '
      '(quota exhausted, rate limited, offline, ...)', () async {
    final primary = _StubService.throws(CampaignAnalysisFailure.server);
    final fallback = _StubService.returns(
      const CampaignAnalysisResult(
        brand: CampaignAnalysisField.confirmed('OCR 결과'),
      ),
    );
    final service = FallbackCampaignAnalysisService(
      primary: primary,
      fallback: fallback,
    );

    final result = await service.analyze(_images());

    expect(result.brand.value, 'OCR 결과');
    expect(primary.callCount, 1);
    expect(fallback.callCount, 1);
  });
}
