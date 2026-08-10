import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';
import 'package:review_calendar/features/registration/domain/campaign_analysis.dart';
import 'package:review_calendar/features/registration/domain/local_campaign_ocr.dart';
import 'package:review_calendar/features/registration/domain/registration_image.dart';
import 'package:review_calendar/screens/upload/upload_flow.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

/// Never touches image_picker or the native `review_calendar/ocr` platform
/// channel — `UploadFlow.imageSource`/`analysisService` are injected fakes,
/// exercising the real wiring (`_pickAndAnalyze` → `_startAnalyzing` →
/// pre-filled confirm screen → real campaign save) around them, with
/// `UploadFlow` pumped directly rather than through the full app/tab
/// navigation. The OCR text-parsing logic itself is covered separately in
/// `local_campaign_ocr_test.dart` (ported verbatim from the sibling).
final class _FakeImageSource implements RegistrationImageSource {
  _FakeImageSource(this.candidates);

  final List<RegistrationImageCandidate> candidates;

  @override
  Future<List<RegistrationImageCandidate>> pickGallery({
    required int limit,
  }) async => candidates;

  @override
  Future<List<RegistrationImageCandidate>> takePhoto() async => const [];

  @override
  Future<List<RegistrationImageCandidate>> recoverLostImages() async =>
      const [];
}

final class _FakeAnalysisService implements LocalCampaignAnalysisService {
  const _FakeAnalysisService(this.result);

  final CampaignAnalysisResult result;

  @override
  Future<CampaignAnalysisResult> analyze(List<RegistrationImage> images) =>
      Future.value(result);
}

RegistrationImageCandidate _candidate(String id) => RegistrationImageCandidate(
  id: id,
  name: '$id.png',
  mimeType: 'image/png',
  readBytes: () async => Uint8List.fromList([0, 1, 2]),
);

void main() {
  testWidgets(
    'picking a screenshot runs the injected OCR analysis and pre-fills the '
    'confirm screen, which saves a real campaign',
    (tester) async {
      final repository = FakeCampaignRepository();
      const analysisResult = CampaignAnalysisResult(
        brand: CampaignAnalysisField.confirmed('성수 브런치'),
        platform: CampaignAnalysisField.confirmed('블로그'),
        category: CampaignAnalysisField.confirmed('맛집'),
        visitAvailability: CampaignAnalysisField.confirmed(
          CampaignAnalysisVisitAvailability(startDate: '2026-08-12'),
        ),
        deadline: CampaignAnalysisField.confirmed('2026-08-20'),
        sponsoredValue: CampaignAnalysisField.confirmed(68000),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: RcTheme.light(),
          home: UploadFlow(
            categories: const ['맛집', '카페', '기타'],
            campaignRepository: repository,
            ownerId: 'user-001',
            imageSource: _FakeImageSource([_candidate('shot-1')]),
            analysisService: const _FakeAnalysisService(analysisResult),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('갤러리에서 선택'));
      // Progress animation + the (already-resolved) analysis Future settle.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('성수 브런치'), findsOneWidget);

      await tester.tap(find.text('캘린더에 등록하기'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(repository.createCallCount, 1);
      expect(repository.createCalls.single.brand, '성수 브런치');
      expect(repository.createCalls.single.sponsoredValue?.amount, 68000);
    },
  );
}
