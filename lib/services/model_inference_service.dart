import 'dart:isolate';

import 'package:camera/camera.dart';

import '../utils/isolate_utils.dart';
import 'ai_model.dart';
import 'pose_service.dart';
import 'service_locator.dart';


class ModelInferenceService {
  late AiModel model;
  late Function handler;
  late Pose poseService;
  Map<String, dynamic>? inferenceResults;

  Future<void> inference({
    required IsolateUtils isolateUtils,
    required CameraImage cameraImage,
  }) async {
    final responsePort = ReceivePort();

    isolateUtils.sendMessage(
      handler: handler,
      params: {
        'cameraImage': cameraImage,
        'detectorAddress': model.getAddress,
      },
      sendPort: isolateUtils.sendPort,
      responsePort: responsePort,
    );

    inferenceResults = await responsePort.first;
    print('Inference results: $inferenceResults');
    responsePort.close();
  }

  void setModelConfig(int index) {
        model = locator<Pose>();
        handler = runPoseEstimator;
  }
}