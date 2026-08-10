import 'dart:typed_data';

/// Ported verbatim from
/// review-calendar/app/lib/features/registration/domain/registration_image.dart
const int registrationImageLimit = 6;
const int registrationImageByteLimit = 10 * 1024 * 1024;
const Set<String> registrationImageExtensions = {'jpg', 'jpeg', 'png', 'webp'};
const Set<String> registrationImageMimeTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

class RegistrationImage {
  const RegistrationImage({
    required this.id,
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  int get sizeInBytes => bytes.lengthInBytes;
}

class RegistrationImageCandidate {
  const RegistrationImageCandidate({
    required this.id,
    required this.name,
    required this.readBytes,
    this.mimeType,
  });

  final String id;
  final String name;
  final String? mimeType;
  final Future<Uint8List> Function() readBytes;
}

enum RegistrationImagePickerFailure {
  permissionDenied,
  sourceUnavailable,
  busy,
  unknown,
}

class RegistrationImagePickerException implements Exception {
  const RegistrationImagePickerException(this.failure);

  final RegistrationImagePickerFailure failure;
}

abstract interface class RegistrationImageSource {
  Future<List<RegistrationImageCandidate>> pickGallery({required int limit});

  Future<List<RegistrationImageCandidate>> takePhoto();

  Future<List<RegistrationImageCandidate>> recoverLostImages();
}
