import 'package:review_calendar/features/registration/domain/campaign_analysis.dart';
import 'package:review_calendar/features/registration/domain/local_campaign_ocr.dart';
import 'package:review_calendar/features/registration/domain/registration_image.dart';

/// Tries `primary` first, and silently falls back to `fallback` when it
/// fails for any reason — a Gemini free-tier quota running out, a rate
/// limit, a network drop, the provider being down. The user never sees an
/// "AI failed" error; registration just continues on the (always-available,
/// on-device) fallback path instead.
class FallbackCampaignAnalysisService implements LocalCampaignAnalysisService {
  const FallbackCampaignAnalysisService({
    required this.primary,
    required this.fallback,
  });

  final LocalCampaignAnalysisService primary;
  final LocalCampaignAnalysisService fallback;

  @override
  Future<CampaignAnalysisResult> analyze(List<RegistrationImage> images) async {
    try {
      return await primary.analyze(images);
    } on CampaignAnalysisException {
      return fallback.analyze(images);
    }
  }
}
