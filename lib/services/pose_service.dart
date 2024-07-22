import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import 'package:tflite_flutter_helper/tflite_flutter_helper.dart' as helper;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../../utils/image_utils.dart';
import 'package:fisiopose/services/ai_model.dart';

class Pose extends AiModel {
  Interpreter? interpreter;

  Pose({this.interpreter}) {
    loadModel();
  }

  final int inputSize = 256;
  final double threshold = 0.0;
  final List<List<int>> outputShapes = [];
  final List<TfLiteType> outputTypes = [];

  @override
  List<Object> get props => [];

  @override
  int get getAddress => interpreter!.address;

  @override
  Interpreter? get getInterpreter => interpreter;

  get platform => null;

  @override
  helper.TensorImage getProcessedImage(helper.TensorImage inputImage){
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

      final outputTensors = interpreter!.getOutputTensors();
      for (var tensor in outputTensors) {
        outputShapes.add(tensor.shape);
        outputTypes.add(tensor.type);
      }
    } catch (e) {
      log('Error while creating interpreter: $e');
    }
  }

  @override
  Map<String, dynamic>? predict(image_lib.Image image) {
    if (interpreter == null) {
      return null;
    }

    if (Platform.isAndroid) {
      image = image_lib.copyRotate(image, -90);
      image = image_lib.flipHorizontal(image);
    }

    final tensorImage = TensorImage.fromImage(image);
    final inputImage = getProcessedImage(tensorImage);

    final TensorBuffer outputLandmarks = TensorBuffer.createFixedSize(outputShapes[0], TfLiteType.float32);
    final TensorBuffer outputIdentity1 = TensorBuffer.createFixedSize(outputShapes[1], TfLiteType.float32);
    final TensorBuffer outputIdentity2 = TensorBuffer.createFixedSize(outputShapes[2], TfLiteType.float32);
    final TensorBuffer outputIdentity3 = TensorBuffer.createFixedSize(outputShapes[3], TfLiteType.float32);
    final TensorBuffer outputIdentity4 = TensorBuffer.createFixedSize(outputShapes[4], TfLiteType.float32);

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
    final landmarkResults = <Offset>[];

    for (var point in landmarkPoints) {
      landmarkResults.add(Offset(
        point[0] / inputSize * image.width,
        point[1] / inputSize * image.height,
      ));
    }

    return {'point': landmarkResults};
  }
}

Map<String, dynamic>? runPoseEstimator(Map<String, dynamic> params) {
  final pose = Pose(interpreter: Interpreter.fromAddress(params['detectorAddress']));
  dynamic image;
  if (params.containsKey('cameraImage')) {
    image = ImageUtils.convertCameraImage(params['cameraImage']);
  } else if (params.containsKey('imageData')) {
    image = ImageUtils.convertUint8List(params['imageData']);
  }
  final result = pose.predict(image!);
  return result;
}
