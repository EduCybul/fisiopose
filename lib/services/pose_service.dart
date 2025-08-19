import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart' as helper;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import '../../utils/image_utils.dart';
import 'package:fisiopose/services/ai_model.dart';


// ignore: must_be_immutable
class Pose extends AiModel {
  Interpreter? interpreterFisio;
  Interpreter? interpreter;
  String? fisioModelName; // <-- nuevo campo

  Pose({this.interpreter, this.interpreterFisio, this.fisioModelName}) {
    loadModel();
    loadModelFisio(fisioModelName: fisioModelName);
  }


  final int inputSize = 256;
  final double threshold = 0.01;

  @override
  List<Object> get props => [];

  @override
  int get getAddress => interpreter!.address;
  @override
  int get getAdrressFisio => interpreterFisio!.address;

  @override
  Interpreter? get getInterpreter => interpreter;

  @override
  Interpreter? get getintepreterFisio => interpreterFisio;


  @override
  helper.TensorImage getProcessedImage(helper.TensorImage inputImage) {
    final imageProcessor = helper.ImageProcessorBuilder()
        .add(
        helper.ResizeOp(inputSize, inputSize, helper.ResizeMethod.BILINEAR))
        .add(helper.NormalizeOp(0, 255))
        .build();

    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  @override
  Future<void> loadModelFisio({String? fisioModelName}) async {
    try {
      final modelName = fisioModelName ?? 'flexion_hombro_90.tflite';
      interpreterFisio ??=
        await Interpreter.fromAsset('models/$modelName');

      var inputShape = interpreterFisio!.getInputTensor(0).shape;
      var inputType = interpreterFisio!.getInputTensor(0).type;
      print('Another Model Input shape: $inputShape');
      print('Another Model Input type: $inputType');

      var outputShape = interpreterFisio!.getOutputTensor(0).shape;
      var outputType = interpreterFisio!.getOutputTensor(0).type;
      print('Another Model Output shape: $outputShape');
      print('Another Model Output type: $outputType');

      final outputTensors = interpreterFisio!.getOutputTensors();
      for (var tensor in outputTensors) {
        outputShapes.add(tensor.shape);
        outputTypes.add(tensor.type);
        print("Another Model loaded successfully");
      }
    } catch (e) {
      dev.log('Error while creating another interpreter: $e');
    }
  }
  @override
  Future<void> loadModel() async {
    try {
      //final gpuDelegateV2 = tfl.GpuDelegateV2();
      //final interpreterOptions = InterpreterOptions()..addDelegate(gpuDelegateV2);


      interpreter ??= await Interpreter.fromAsset(
        'models/pose_landmark_full.tflite',
        //options: interpreterOptions,
      );


      var inputShape = interpreter!.getInputTensor(0).shape;
      var inputType = interpreter!.getInputTensor(0).type;
      print('Input shape: $inputShape');
      print('Input type: $inputType');

      // Print output tensor information
      var outputShape = interpreter!.getOutputTensor(0).shape;
      var outputType = interpreter!.getOutputTensor(0).type;
      print('Output shape: $outputShape');
      print('Output type: $outputType');

      final outputTensors = interpreter!.getOutputTensors();
      for (var tensor in outputTensors) {
        outputShapes.add(tensor.shape);
        outputTypes.add(tensor.type);
        print("Mediapipe Model loaded successfully");
      }
    } catch (e) {
      dev.log('Error while creating interpreter: $e');
    }
  }


  @override
  Map<String, dynamic>? predictFisio(List<double?> inputMap) {
    if (interpreterFisio == null) {
        print('Interpreter for Fisio model not loaded');
        return null;
    }

    // Debug input
    print('Raw input: $inputMap');

    // Input validation
    if (inputMap.any((element) => element == null)) {
        print('Error: Input contains null values');
        return null;
    }

  
    var inputTensor = TensorBuffer.createFixedSize([1, 99], TfLiteType.float32);
    inputTensor.loadList(inputMap, shape: [1, 99]);

    var outputTensor = TensorBuffer.createFixedSize([1, 1], TfLiteType.float32);
    
    // Run inference
    interpreterFisio!.run(inputTensor.buffer, outputTensor.buffer);

    // Debug raw output
    double rawResult = outputTensor.getDoubleValue(0);
    print('Raw model output: $rawResult');

    double percentageResult = rawResult * 100;

    // Return result as percentage
    return {'inference': double.parse(percentageResult.toStringAsFixed(2))};
}

  @override
  Map<String, dynamic>? predict(image_lib.Image image) {
    if (interpreter == null) {
      return null;
    }

    //if (Platform.isAndroid) {
    // image = image_lib.copyRotate(image, -90);
    //image = image_lib.flipHorizontal(image);
    // }

    final tensorImage = helper.TensorImage.fromImage(image);
    final inputImage = getProcessedImage(tensorImage);

    final helper.TensorBuffer outputLandmarks = helper.TensorBuffer
        .createFixedSize(
        outputShapes[0], TfLiteType.float32);
    final helper.TensorBuffer outputIdentity1 = helper.TensorBuffer
        .createFixedSize(
        outputShapes[1], TfLiteType.float32);
    final helper.TensorBuffer outputIdentity2 = helper.TensorBuffer
        .createFixedSize(
        outputShapes[2], TfLiteType.float32);
    final helper.TensorBuffer outputIdentity3 = helper.TensorBuffer
        .createFixedSize(
        outputShapes[3], TfLiteType.float32);
    final helper.TensorBuffer outputIdentity4 = helper.TensorBuffer
        .createFixedSize(
        outputShapes[4], TfLiteType.float32);

    final inputs = <Object>[inputImage.buffer];
    final outputs = <int, Object>{
      0: outputLandmarks.buffer,
      1: outputIdentity1.buffer,
      2: outputIdentity2.buffer,
      3: outputIdentity3.buffer,
      4: outputIdentity4.buffer,
    };

    interpreter!.runForMultipleInputs(inputs, outputs);

    if (outputIdentity1.getDoubleValue(0) < threshold) {
      return null;
    }

    final landmarkPoints = outputLandmarks.getDoubleList().reshape([39, 5]);
    print('landmarkPoints: $landmarkPoints');




    final landmarkResults = <Map<String, double>>[];
    print('Image width: ${image.width}');
    print('Image height: ${image.height}');
    print('landmarkPoints: $landmarkPoints');
    for (var point in landmarkPoints) {
      landmarkResults.add({
        'x': point[0] / inputSize * image.width,
        'y': point[1] / inputSize * image.height,
        'z': point[2]
      });
    }

    print('landmarkPoints normalizados a la imagen : $landmarkResults');
    return {'point': landmarkResults};
  }


}

Map<String, dynamic>? runPoseEstimatorFisio(Map<String, dynamic> params)  {
  final pose = Pose(
    interpreterFisio: Interpreter.fromAddress(params['detectorAddress']),
    fisioModelName: params['fisioModelName'], // <-- recibe el nombre del modelo
  );
  final filteredpoints = filterLandmarks(params['points']);
  final puntosnormalizados= normalizePoints(filteredpoints, 256);

  final result = pose.predictFisio(puntosnormalizados);
  return result;
}

  Map<String, dynamic>? runPoseEstimator(Map<String, dynamic> params) {
    final pose = Pose(
        interpreter: Interpreter.fromAddress(params['detectorAddress']));
    dynamic image;
    if (params.containsKey('cameraImage')) {
      image = ImageUtils.convertCameraImage(params['cameraImage']);
    } else if (params.containsKey('imageData')) {
      image = ImageUtils.convertUint8List(params['imageData']);
    }
    final result = pose.predict(image!);
    return result;
  }
Map<String, dynamic> filterLandmarks(Map<String, dynamic> inputMap) {
  // Filtrar solo los primeros 33 puntos (66 valores, 33 para X y 33 para Y)
  Map<String, double> filteredMap = {};
  for (int i = 0; i < 33; i++) {
    filteredMap["x$i"] = inputMap["x$i"] ?? 0.0;
    filteredMap["y$i"] = inputMap["y$i"] ?? 0.0;
    filteredMap["z$i"] = inputMap["z$i"] ?? 0.0;
  }
  return filteredMap;
}

List<double> normalizePoints(Map<String, dynamic> landmarkPoints, int inputSize) {
  List<double> normalizedPoints = [];
  for (var i = 0; i < 33; i++) {
    normalizedPoints.add(landmarkPoints["x$i"] / inputSize);
    normalizedPoints.add(landmarkPoints["y$i"] / inputSize);
    normalizedPoints.add(landmarkPoints["z$i"] / inputSize);
  }
  return normalizedPoints;
}

