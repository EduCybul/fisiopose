import 'dart:developer' as dev;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import 'package:tflite_flutter_helper/tflite_flutter_helper.dart' as helper;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../../utils/image_utils.dart';
import 'package:fisiopose/services/ai_model.dart';

class Pose {
  static final Pose _instance = Pose._internal();
  Interpreter? interpreterfisio;
  Interpreter? interpreter;

  factory Pose(){
    return _instance;
  }

  Pose._internal(){
    _loadModel();
    _loadmodelfisio();
  }

  final int inputSize = 256;
  final double threshold = 0.001;
  final List<List<int>> outputShapes = [];
  final List<TfLiteType> outputTypes = [];

  final List<List<int>> outputShapesfisio = [];
  final List<TfLiteType> outputTypesfisio = [];


  bool _modelLoaded = false;
  bool _fisioModelLoaded = false;


  @override
  List<Object> get props => [];

  @override
  int get getAddress => interpreter!.address;

  @override
  int get getAddressfisio => interpreterfisio!.address;

  @override
  Interpreter? get getInterpreterfisio => interpreterfisio;

  @override
  Interpreter? get getInterpreter => interpreter;

  get platform => null;

  @override
  helper.TensorImage getProcessedImage(helper.TensorImage inputImage) {
    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(inputSize, inputSize, helper.ResizeMethod.BILINEAR))
        .add(NormalizeOp(0, 255))
        .build();

    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  @override
  Future<void> _loadModel() async {
    if (_modelLoaded) {return;}
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
      _modelLoaded =true;
    } catch (e) {
      dev.log('Error while creating interpreter: $e');
    }
  }


  @override
  Future<void> _loadmodelfisio() async {
    if(_fisioModelLoaded){return;}
    try {
      interpreterfisio ??=  await Interpreter.fromAsset('models/flexionhombro90-frente.tflite');


      // Print input tensor information
      var inputShape = interpreterfisio!.getInputTensor(0).shape;
      var inputShape2 = interpreterfisio!.getInputTensor(1).shape;
      var inputType = interpreterfisio!.getInputTensor(0).type;
      print('Input shape: $inputShape');
      print('Input shape: $inputShape2');
      print('Input type: $inputType');

      // Print output tensor information
      var outputShape = interpreterfisio!.getOutputTensor(0).shape;
      var outputType = interpreterfisio!.getOutputTensor(0).type;
      print('Output shape: $outputShape');
      print('Output type: $outputType');

      final outputTensors = interpreterfisio!.getOutputTensors();

      for (var tensor in outputTensors) {
        outputShapesfisio.add(tensor.shape);
        outputTypesfisio.add(tensor.type);
      }
      _fisioModelLoaded =true;
      print("Fisio Model loaded successfully");
    } catch (e) {
      print('Error while creating interpreter: $e');
    }
  }

  @override
  Map<String, dynamic>? predictfisio(List<Offset> landmarks) {
    {
      if (interpreterfisio == null) {
        print("Fisio Interpreter no inicializado");
        return null;
      }

      final input = _prepareInput(landmarks);

      //List<double> input = calcDist(landmarks);
      List<List<double>> a = [
        [10,   2,  4,  6,  -2,  0,  0,  0,  0,  0,  0,  0, 0,0,0,0,0,0,0,0,0,0,0]];


      // Define the shape of the output
      //final output = List<double>.filled(1, 0).reshape([1, 1]);

      final TensorBuffer output = TensorBuffer.createFixedSize(
          outputShapesfisio[0], TfLiteType.float32);

      final outputfinal = <int, Object>{  0: output.buffer};


      interpreterfisio!.runForMultipleInputs(a, outputfinal);

      print("Prediction: $outputfinal");
    }
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

      final tensorImage = TensorImage.fromImage(image);
      final inputImage = getProcessedImage(tensorImage);

      final TensorBuffer outputLandmarks = TensorBuffer.createFixedSize(
          outputShapes[0], TfLiteType.float32);
      final TensorBuffer outputIdentity1 = TensorBuffer.createFixedSize(
          outputShapes[1], TfLiteType.float32);
      final TensorBuffer outputIdentity2 = TensorBuffer.createFixedSize(
          outputShapes[2], TfLiteType.float32);
      final TensorBuffer outputIdentity3 = TensorBuffer.createFixedSize(
          outputShapes[3], TfLiteType.float32);
      final TensorBuffer outputIdentity4 = TensorBuffer.createFixedSize(
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

      print('outputIdentity1: ${outputIdentity1.getDoubleValue(0)}');
      if (outputIdentity1.getDoubleValue(0) < threshold) {
        return null;
      }

      final landmarkPoints = outputLandmarks.getDoubleList().reshape([39, 5]);
      final landmarkResults = <Map<String, double>>[];

      for (var point in landmarkPoints) {
        landmarkResults.add({
          'x': point[0] / inputSize * image.width,
          'y': point[1] / inputSize * image.height,
          'z': point[2]
        });
      }

      return {'point': landmarkResults};
    }
  }

  Map<String, dynamic>? runPoseEstimator(Map<String, dynamic> params) {
    final pose = Pose();
    dynamic image;
    if (params.containsKey('cameraImage')) {
      image = ImageUtils.convertCameraImage(params['cameraImage']);
    } else if (params.containsKey('imageData')) {
      image = ImageUtils.convertUint8List(params['imageData']);
    }
    final result = pose.predict(image!);
    return result;
  }

  Map<String, dynamic>? runPoseEstimatorFisio(Map<String, dynamic> params) {
    final pose = Pose();

    print('Landmarks parameter: ${params['landmarks']}');

    List<Offset> landmarksResults = params.containsKey('landmarks')
        ? List<Offset>.from(params['landmarks'])
        : [];
    final result = pose.predictfisio(landmarksResults);
    return result;
  }

double calculateDistance(Offset point1, Offset point2) {//Función para calcular la distancia entre 2 puntos.
  return sqrt(pow(point2.dx - point1.dx, 2) + pow(point2.dy - point1.dy, 2));
}

//Funcion que calcula las distancias entre todos los puntos dados.
List<double> calcDist (List<Offset> landmarks){
  if(landmarks.isEmpty){
    return [];
  }
  List<double> distances = [
    calculateDistance(landmarks[16], landmarks[27]), // RIGHT_WRIST_LEFT_ANKLE_distance
    calculateDistance(landmarks[24], landmarks[26]), // RIGHT_HIP_RIGHT_KNEE_distance
    calculateDistance(landmarks[0], landmarks[26]), // NOSE_RIGHT_KNEE_distance
    calculateDistance(landmarks[12], landmarks[16]), // RIGHT_SHOULDER_RIGHT_WRIST_distance
    calculateDistance(landmarks[12], landmarks[26]), // RIGHT_SHOULDER_RIGHT_KNEE_distance
    calculateDistance(landmarks[24], landmarks[14]), // RIGHT_HIP_RIGHT_ELBOW_distance
    calculateDistance(landmarks[23], landmarks[15]), // LEFT_HIP_LEFT_WRIST_distance
    calculateDistance(landmarks[15], landmarks[27]), // LEFT_WRIST_LEFT_ANKLE_distance
    calculateDistance(landmarks[23], landmarks[27]), // LEFT_HIP_LEFT_ANKLE_distance
    calculateDistance(landmarks[11], landmarks[15]), // LEFT_SHOULDER_LEFT_WRIST_distance
    calculateDistance(landmarks[23], landmarks[31]), // LEFT_HIP_LEFT_FOOT_INDEX_distance
    calculateDistance(landmarks[24], landmarks[32]), // RIGHT_HIP_RIGHT_FOOT_INDEX_distance
    calculateDistance(landmarks[11], landmarks[31]), // LEFT_SHOULDER_LEFT_FOOT_INDEX_distance
    calculateDistance(landmarks[15], landmarks[28]), // LEFT_WRIST_RIGHT_ANKLE_distance
    calculateDistance(landmarks[11], landmarks[25]), // LEFT_SHOULDER_LEFT_KNEE_distance
    calculateDistance(landmarks[0], landmarks[25]), // NOSE_LEFT_KNEE_distance
    calculateDistance(landmarks[16], landmarks[28]), // RIGHT_WRIST_RIGHT_ANKLE_distance
    calculateDistance(landmarks[12], landmarks[32]), // RIGHT_SHOULDER_RIGHT_FOOT_INDEX_distance
    calculateDistance(landmarks[24], landmarks[16]), // RIGHT_HIP_RIGHT_WRIST_distance
    calculateDistance(landmarks[24], landmarks[28]), // RIGHT_HIP_RIGHT_ANKLE_distance
    calculateDistance(landmarks[23], landmarks[25]), // LEFT_HIP_LEFT_KNEE_distance
    calculateDistance(landmarks[23], landmarks[13]), // LEFT_HIP_LEFT_ELBOW_distance
    calculateDistance(landmarks[15], landmarks[16]), // LEFT_WRIST_RIGHT_WRIST_distance
  ];

  print('Calculated distances: $distances');

  return distances;

}

List<List<List<double>>> _prepareInput(List<Offset> landmarks) {
  // Convert landmarks to a 2D list and pad if necessary
  final input = List.generate(landmarks.length, (i) => [landmarks[i].dx, landmarks[i].dy]);

  // Ensure the input dimensions match the model's expected input dimensions
  if (input.length < 46) {
    input.addAll(List.generate(46 - input.length, (_) => [0.0, 0.0]));
  }

  return [input];
}

