import 'package:flutter/services.dart';
import 'package:review_calendar/features/registration/domain/local_campaign_ocr.dart';
import 'package:review_calendar/features/registration/domain/registration_image.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/registration/data/apple_vision_campaign_ocr_engine.dart
/// — calls into the native `review_calendar/ocr` MethodChannel registered in
/// `AppDelegate.swift` (iOS's Vision framework), also ported verbatim.
final class AppleVisionCampaignOcrEngine implements CampaignOcrEngine {
  const AppleVisionCampaignOcrEngine({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('review_calendar/ocr');

  final MethodChannel _channel;

  @override
  Future<String> recognize(RegistrationImage image) async {
    final text = await _channel.invokeMethod<String>('recognizeText', {
      'bytes': image.bytes,
    });
    return text ?? '';
  }
}
