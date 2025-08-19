
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

// ignore: must_be_immutable
abstract class AiModel extends Equatable {
  AiModel();

  final outputShapes = <List<int>>[];
  final outputTypes = <TfLiteType>[];

  Interpreter? getInterpreter;
  Interpreter? getintepreterFisio;

  @override
  List<Object> get props => [];

  int get getAddress;

  int get getAdrressFisio;

  Future<void> loadModel();
  Future<void> loadModelFisio();
  TensorImage getProcessedImage(TensorImage inputImage);
  Map<String, dynamic>? predict(image_lib.Image image);
  Map<String, dynamic>? predictFisio(List<double> inputMap);
}
