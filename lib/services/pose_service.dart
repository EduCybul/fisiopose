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

// ignore: must_be_immutable
class Pose extends AiModel {
  Interpreter? interpreter;

  Pose({this.interpreter}) {
    loadModel();
  }


  final int inputSize = 256;
  final double threshold = 0.01;


  @override
  List<Object> get props => [];

  @override
  int get getAddress => interpreter!.address;

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
      /*
      final landmarkResults = <Offset>[];
      for (var point in landmarkPoints) {
        landmarkResults.add(Offset(
          point[0] / inputSize * image.width,
          point[1] / inputSize * image.height,
        ));
      */
      }

      print('landmarkPoints normalizados : $landmarkResults');
      return {'point': landmarkResults};
    }
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


  double calculateDistance(Offset point1, Offset point2) {
    //Función para calcular la distancia entre 2 puntos.
    return sqrt(pow(point2.dx - point1.dx, 2) + pow(point2.dy - point1.dy, 2));
  }

//Funcion que calcula las distancias entre todos los puntos dados.
  List<double> calcDist(List<Offset> landmarks) {
    if (landmarks.isEmpty) {
      return [];
    }
    List<double> distances = [
      calculateDistance(landmarks[16], landmarks[27]),
      // RIGHT_WRIST_LEFT_ANKLE_distance
      calculateDistance(landmarks[24], landmarks[26]),
      // RIGHT_HIP_RIGHT_KNEE_distance
      calculateDistance(landmarks[0], landmarks[26]),
      // NOSE_RIGHT_KNEE_distance
      calculateDistance(landmarks[12], landmarks[16]),
      // RIGHT_SHOULDER_RIGHT_WRIST_distance
      calculateDistance(landmarks[12], landmarks[26]),
      // RIGHT_SHOULDER_RIGHT_KNEE_distance
      calculateDistance(landmarks[24], landmarks[14]),
      // RIGHT_HIP_RIGHT_ELBOW_distance
      calculateDistance(landmarks[23], landmarks[15]),
      // LEFT_HIP_LEFT_WRIST_distance
      calculateDistance(landmarks[15], landmarks[27]),
      // LEFT_WRIST_LEFT_ANKLE_distance
      calculateDistance(landmarks[23], landmarks[27]),
      // LEFT_HIP_LEFT_ANKLE_distance
      calculateDistance(landmarks[11], landmarks[15]),
      // LEFT_SHOULDER_LEFT_WRIST_distance
      calculateDistance(landmarks[23], landmarks[31]),
      // LEFT_HIP_LEFT_FOOT_INDEX_distance
      calculateDistance(landmarks[24], landmarks[32]),
      // RIGHT_HIP_RIGHT_FOOT_INDEX_distance
      calculateDistance(landmarks[11], landmarks[31]),
      // LEFT_SHOULDER_LEFT_FOOT_INDEX_distance
      calculateDistance(landmarks[15], landmarks[28]),
      // LEFT_WRIST_RIGHT_ANKLE_distance
      calculateDistance(landmarks[11], landmarks[25]),
      // LEFT_SHOULDER_LEFT_KNEE_distance
      calculateDistance(landmarks[0], landmarks[25]),
      // NOSE_LEFT_KNEE_distance
      calculateDistance(landmarks[16], landmarks[28]),
      // RIGHT_WRIST_RIGHT_ANKLE_distance
      calculateDistance(landmarks[12], landmarks[32]),
      // RIGHT_SHOULDER_RIGHT_FOOT_INDEX_distance
      calculateDistance(landmarks[24], landmarks[16]),
      // RIGHT_HIP_RIGHT_WRIST_distance
      calculateDistance(landmarks[24], landmarks[28]),
      // RIGHT_HIP_RIGHT_ANKLE_distance
      calculateDistance(landmarks[23], landmarks[25]),
      // LEFT_HIP_LEFT_KNEE_distance
      calculateDistance(landmarks[23], landmarks[13]),
      // LEFT_HIP_LEFT_ELBOW_distance
      calculateDistance(landmarks[15], landmarks[16]),
      // LEFT_WRIST_RIGHT_WRIST_distance
    ];
    print('Calculated distances: $distances');
    return distances;
}


