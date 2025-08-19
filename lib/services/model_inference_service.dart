import 'dart:isolate';
import 'dart:typed_data';

import '../utils/isolate_utils.dart';
import 'ai_model.dart';
import 'package:fisiopose/services/pose_service.dart';


import 'service_locator.dart';

class ModelInferenceService {

  Map<String, dynamic>? inferenceResults;
  Map<String, dynamic>? predictFisioResult;
  late AiModel model;
  late Function handler ;
  late Function handlerFisio ;
  late AiModel modelFisio;

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

  Future<void> inferencePoints({
    required IsolateUtils isolateUtils,
    required Map<String,dynamic> points,
    String? fisioModelName, // <-- nuevo parámetro
  }) async {
    final responsePort = ReceivePort();

    isolateUtils.sendMessage(
      handler: handlerFisio,
      params: {
        'points': points,
        'detectorAddress': modelFisio.getAdrressFisio,
        'fisioModelName': fisioModelName, // <-- pasa el nombre del modelo
      },
      sendPort: isolateUtils.sendPort,
      responsePort: responsePort,
    );

    predictFisioResult = await responsePort.first;
    responsePort.close();
  }


  void setModelConfig(){
        model = locator<Pose>() ;
        modelFisio = locator<Pose>() ;
        handler = runPoseEstimator;
        handlerFisio = runPoseEstimatorFisio;

  }


}
