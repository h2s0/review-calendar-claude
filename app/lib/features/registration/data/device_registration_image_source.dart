import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:review_calendar/features/registration/domain/registration_image.dart';

/// Ported verbatim from
/// review-calendar/app/lib/features/registration/data/device_registration_image_source.dart
class DeviceRegistrationImageSource implements RegistrationImageSource {
  DeviceRegistrationImageSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<RegistrationImageCandidate>> pickGallery({
    required int limit,
  }) async {
    try {
      final files = await _picker.pickMultiImage(
        limit: limit,
        requestFullMetadata: false,
      );
      return files.map(_candidate).toList(growable: false);
    } on PlatformException catch (error) {
      throw _mappedException(error);
    }
  }

  @override
  Future<List<RegistrationImageCandidate>> takePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );
      return file == null ? const [] : [_candidate(file)];
    } on PlatformException catch (error) {
      throw _mappedException(error);
    }
  }

  @override
  Future<List<RegistrationImageCandidate>> recoverLostImages() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return const [];
      }
      if (response.exception case final error?) {
        throw _mappedException(error);
      }
      final files = response.files ?? [?response.file];
      return files.map(_candidate).toList(growable: false);
    } on UnimplementedError {
      return const [];
    } on PlatformException catch (error) {
      throw _mappedException(error);
    }
  }

  RegistrationImageCandidate _candidate(XFile file) {
    return RegistrationImageCandidate(
      id: file.path,
      name: file.name,
      mimeType: file.mimeType,
      readBytes: file.readAsBytes,
    );
  }

  RegistrationImagePickerException _mappedException(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('access_denied') ||
        code.contains('permission') ||
        code.contains('restricted')) {
      return const RegistrationImagePickerException(
        RegistrationImagePickerFailure.permissionDenied,
      );
    }
    if (code.contains('no_available_camera') ||
        code.contains('camera_not_supported')) {
      return const RegistrationImagePickerException(
        RegistrationImagePickerFailure.sourceUnavailable,
      );
    }
    if (code.contains('already_active') || code.contains('in_use')) {
      return const RegistrationImagePickerException(
        RegistrationImagePickerFailure.busy,
      );
    }
    return const RegistrationImagePickerException(
      RegistrationImagePickerFailure.unknown,
    );
  }
}
