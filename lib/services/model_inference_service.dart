import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';

import '../utils/isolate_utils.dart';
import 'ai_model.dart';
import 'package:fisiopose/services/pose_service.dart';


import 'service_locator.dart';

class ModelInferenceService {
  Map<String, dynamic>? inferenceResults;

  late AiModel model;
  late Function handler ;

  Future<void> inference({
    required IsolateUtils isolateUtils,
    required CameraImage cameraImage,
  }) async {
    final responsePort = ReceivePort();

    isolateUtils.sendMessage(
      handler: runPoseEstimator,
      params: {
        'cameraImage': cameraImage,
        'detectorAddress': model.getAddress,
      },
      sendPort: isolateUtils.sendPort,
      responsePort: responsePort,
    );

    inferenceResults = await responsePort.first;
    responsePort.close();
  }
  Future<void> inferenceWithUint8List({
    required IsolateUtils isolateUtils,
    required Uint8List imageData,
  }) async {
    final responsePort = ReceivePort();

    isolateUtils.sendMessage(
      handler: handler,
      params: {
        'imageData': imageData,
        'detectorAddress': model.getAddress,
      },
      sendPort: isolateUtils.sendPort,
      responsePort: responsePort,
    );

    inferenceResults = await responsePort.first;
    responsePort.close();
  }

  void setModelConfig(){
        model = locator<Pose>() ;
        handler = runPoseEstimator;
       // handlerImage = runPoseEstimator;

  }

}
