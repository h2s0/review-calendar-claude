import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Ported verbatim from review-calendar/app/ios/Runner/AppDelegate.swift —
  // backs `AppleVisionCampaignOcrEngine`'s `review_calendar/ocr` MethodChannel
  // with on-device Vision text recognition (no network/server round-trip).
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "review_calendar/ocr",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let typedData = arguments["bytes"] as? FlutterStandardTypedData,
        let image = UIImage(data: typedData.data),
        let cgImage = image.cgImage
      else {
        result(FlutterError(code: "invalid_image", message: "이미지를 읽을 수 없어요.", details: nil))
        return
      }

      Self.recognizeText(in: cgImage, completion: result)
    }
  }

  private static func recognizeText(
    in image: CGImage,
    completion: @escaping FlutterResult
  ) {
    let request = VNRecognizeTextRequest { request, error in
      if let error {
        DispatchQueue.main.async {
          completion(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
        }
        return
      }
      let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
      let text = observations
        .sorted {
          let rowDifference = abs($0.boundingBox.midY - $1.boundingBox.midY)
          return rowDifference > 0.02
            ? $0.boundingBox.midY > $1.boundingBox.midY
            : $0.boundingBox.minX < $1.boundingBox.minX
        }
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")
      DispatchQueue.main.async { completion(text) }
    }
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["ko-KR", "en-US"]
    request.usesLanguageCorrection = true

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try VNImageRequestHandler(cgImage: image).perform([request])
      } catch {
        DispatchQueue.main.async {
          completion(FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
