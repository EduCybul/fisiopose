import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';

import '../utils/isolate_utils.dart';
import 'ai_model.dart';
import 'package:fisiopose/services/pose_service.dart';
import 'package:fisiopose/services/pose_service.dart' as pose;

import 'service_locator.dart';

class ModelInferenceService {
late  Pose pose;

ModelInferenceService(){
  pose =Pose();
}
Pose get getPose => pose;

  Map<String, dynamic>? inferenceResults;

  late Function handlerImage;
  Map<String, dynamic>? inferenceResultsImage;

  late Function handlerFisio;
  Map<String, dynamic>? inferenceResultsFisio;

  Future<void> inference({
    required IsolateUtils isolateUtils,
    required CameraImage cameraImage,
  }) async {
    final responsePort = ReceivePort();

    isolateUtils.sendMessage(
      handler: runPoseEstimator,
      params: {
        'cameraImage': cameraImage,
        'detectorAddress': pose.interpreter!.address,
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
      handler: runPoseEstimator,
      params: {
        'imageData': imageData,
        'detectorAddress': pose.interpreterfisio!.address,
      },
      sendPort: isolateUtils.sendPort,
      responsePort: responsePort,
    );

    inferenceResultsImage = await responsePort.first;
    responsePort.close();
  }
  Future<void> inferenceFisio({
    required IsolateUtils isolateUtils,
    required List<Offset> landmarksResults,
  }) async {
    final responsePort = ReceivePort();

    isolateUtils.sendMessage(
      handler: runPoseEstimatorFisio,
      params: {
        'landmarks': landmarksResults,
        'detectorAddress': pose.interpreterfisio!.address,
      },
      sendPort: isolateUtils.sendPort,
      responsePort: responsePort,
    );

    inferenceResultsFisio  = await responsePort.first;
    responsePort.close();
  }
  /*
  void setModelConfig(int index){
        model = locator<Pose>();
        handler = runPoseEstimator;
        handlerImage = runPoseEstimator;
        handlerFisio = pose.runPoseEstimatorFisio;

  }
  */
}
