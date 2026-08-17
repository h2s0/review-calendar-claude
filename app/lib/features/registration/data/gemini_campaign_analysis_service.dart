import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:review_calendar/core/identity/id_generator.dart';
import 'package:review_calendar/features/registration/domain/campaign_analysis.dart';
import 'package:review_calendar/features/registration/domain/campaign_registration_draft.dart';
import 'package:review_calendar/features/registration/domain/local_campaign_ocr.dart';
import 'package:review_calendar/features/registration/domain/registration_image.dart';

const _allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

/// Calls the `analyzeCampaignScreenshots` Cloud Function (Gemini vision,
/// see review-calendar/firebase/src/campaign-analysis.js) instead of the
/// on-device Vision OCR path (`OcrCampaignAnalysisService`) — understands
/// screenshot layout/context instead of pattern-matching flat OCR text, at
/// the cost of a network round-trip.
///
/// Uploads each image to Storage at the exact `analysis-temp/{uid}/{requestId}/`
/// path the function's own request validation requires, then deletes them
/// itself server-side once analysis finishes (success or failure) — this
/// service never needs to clean up after itself.
class GeminiCampaignAnalysisService implements LocalCampaignAnalysisService {
  GeminiCampaignAnalysisService({
    required this.functions,
    required this.storage,
    required this.ownerId,
    IdGenerator? idGenerator,
  }) : _idGenerator = idGenerator ?? RandomIdGenerator();

  final FirebaseFunctions functions;
  final FirebaseStorage storage;
  final String ownerId;
  final IdGenerator _idGenerator;

  @override
  Future<CampaignAnalysisResult> analyze(List<RegistrationImage> images) async {
    if (images.isEmpty) {
      throw const CampaignAnalysisException(
        CampaignAnalysisFailure.invalidResponse,
      );
    }

    try {
      final requestId = _idGenerator.nextId();
      final references = <Map<String, Object?>>[];
      for (var index = 0; index < images.length; index++) {
        final image = images[index];
        final mimeType = _normalizedMimeType(image.mimeType);
        final path =
            'analysis-temp/$ownerId/$requestId/image-$index'
            '${_extensionFor(mimeType)}';
        await storage
            .ref(path)
            .putData(image.bytes, SettableMetadata(contentType: mimeType));
        references.add({
          'path': path,
          'mimeType': mimeType,
          'sizeBytes': image.bytes.lengthInBytes,
        });
      }

      final result = await functions
          .httpsCallable(
            'analyzeCampaignScreenshots',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 60),
              limitedUseAppCheckToken: true,
            ),
          )
          .call<Object?>({'requestId': requestId, 'images': references});
      return resultFromJson(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw CampaignAnalysisException(_failureFor(error.code));
    } on CampaignAnalysisException {
      rethrow;
    } catch (_) {
      // Any other failure (network drop mid-upload, etc.) — surface it as
      // the same exception type FallbackCampaignAnalysisService expects,
      // rather than letting a raw platform exception escape.
      throw const CampaignAnalysisException(CampaignAnalysisFailure.offline);
    }
  }
}

String _normalizedMimeType(String? mimeType) =>
    mimeType != null && _allowedMimeTypes.contains(mimeType)
    ? mimeType
    : 'image/jpeg';

String _extensionFor(String mimeType) => switch (mimeType) {
  'image/png' => '.png',
  'image/webp' => '.webp',
  _ => '.jpg',
};

CampaignAnalysisFailure _failureFor(String code) => switch (code) {
  'deadline-exceeded' => CampaignAnalysisFailure.timeout,
  'internal' => CampaignAnalysisFailure.invalidResponse,
  _ => CampaignAnalysisFailure.server,
};

/// The Functions plugin deserializes nested platform-channel payloads as
/// `Map<Object?, Object?>` (not `Map<String, dynamic>`) on some platforms —
/// normalize at every level rather than trusting the static type.
Map<String, dynamic> _normalizeMap(Object? raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

CampaignAnalysisField<T> _field<T>(
  Object? raw,
  T? Function(Object? value) parseValue,
) {
  final map = _normalizeMap(raw);
  if (map.isEmpty) return CampaignAnalysisField<T>();
  return CampaignAnalysisField<T>(
    value: parseValue(map['value']),
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
    needsReview: map['needsReview'] as bool? ?? true,
    evidence: map['evidence'] as String?,
  );
}

/// The pure JSON-to-domain-model half of this service — exported
/// separately so it's directly unit-testable without a real Firebase
/// connection (the rest of the class is thin Storage/Functions plumbing).
CampaignAnalysisResult resultFromJson(Object? raw) {
  final json = _normalizeMap(raw);
  return CampaignAnalysisResult(
    brand: _field<String>(json['brand'], (v) => v as String?),
    platform: _field<String>(json['platform'], (v) => v as String?),
    category: _field<String>(json['category'], (v) => v as String?),
    visitAvailability: _field<CampaignAnalysisVisitAvailability>(
      json['visitAvailability'],
      (v) {
        final inner = _normalizeMap(v);
        final start = inner['startDate'] as String?;
        return start == null
            ? null
            : CampaignAnalysisVisitAvailability(
                startDate: start,
                endDate: inner['endDate'] as String?,
              );
      },
    ),
    availableTimes: _field<List<VisitTimeRangeDraft>>(json['availableTimes'], (
      v,
    ) {
      if (v is! List) return null;
      final times = v
          .map((item) {
            final inner = _normalizeMap(item);
            return VisitTimeRangeDraft(
              start: inner['start'] as String? ?? '',
              end: inner['end'] as String? ?? '',
            );
          })
          .toList(growable: false);
      return times.isEmpty ? null : times;
    }),
    deadline: _field<String>(json['deadline'], (v) => v as String?),
    contactName: _field<String>(json['contactName'], (v) => v as String?),
    contactPhone: _field<String>(json['contactPhone'], (v) => v as String?),
    sponsoredValue: _field<int>(
      json['sponsoredValue'],
      (v) => (v as num?)?.toInt(),
    ),
    cashFee: _field<int>(json['cashFee'], (v) => (v as num?)?.toInt()),
    notes: _field<String>(json['notes'], (v) => v as String?),
    rawDeadlineText: _field<String>(
      json['rawDeadlineText'],
      (v) => v as String?,
    ),
    mixedCampaignWarning: _mixedWarningFromJson(json['mixedCampaignWarning']),
  );
}

CampaignAnalysisMixedCampaignWarning _mixedWarningFromJson(Object? raw) {
  final map = _normalizeMap(raw);
  return CampaignAnalysisMixedCampaignWarning(
    suspected: map['suspected'] as bool? ?? false,
    message: map['message'] as String?,
  );
}
