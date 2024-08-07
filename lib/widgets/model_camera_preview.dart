import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../services/model_inference_service.dart';
import '../../../services/service_locator.dart';
import 'pose_painter.dart';

class ModelCameraPreview extends StatefulWidget {
  const ModelCameraPreview({
    super.key,
    required this.cameraController,
    required this.index,
    required this.draw,
    this.imageData,
  });

  final CameraController? cameraController;
  final int index;
  final bool draw;
  final Uint8List? imageData;

  @override
  ModelCameraPreviewState createState() => ModelCameraPreviewState();
}

class ModelCameraPreviewState extends State<ModelCameraPreview> {
  late double _ratio;
  Map<String, dynamic>? inferenceResultsImage;
  Map<String, dynamic>? inferenceResults;

  @override
  void initState() {
    super.initState();
    inferenceResultsImage = locator<ModelInferenceService>().inferenceResultsImage ?? {};
    inferenceResults = locator<ModelInferenceService>().inferenceResults ?? {};
  }

  void updateInferenceResults(List<dynamic> pointss) {
    print('Received points: $pointss' );
    setState(() {
      inferenceResultsImage = locator<ModelInferenceService>().inferenceResultsImage ?? {};
      inferenceResults = locator<ModelInferenceService>().inferenceResults ?? {};
    //  final convertedPoints = _convertPoints(pointss);
      // print('convertedPoints:  $convertedPoints');
      print('inferenceResultsImage:  $inferenceResultsImage');
      print('inferenceResultsImage:  $inferenceResults');
    });
  }

 // List<Offset> _convertPoints(List<dynamic>? points) {
 //   if (points ==null) return [];
 //   return points.where((point) => point is List && point.length >= 2).map((point) => Offset(point[0], point[1])).toList();
 // }

  @override
  Widget build(BuildContext context) {
    if (widget.cameraController == null || !widget.cameraController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    _ratio = screenSize.width / widget.cameraController!.value.previewSize!.height;
    //final points =  _convertPoints(inferenceResultsImage?['point'] ?? inferenceResults?['point']);
   // print('Coordenadas a pintar: $points');

    return Stack(
      children: [
        if (widget.imageData != null)
          Image.memory(widget.imageData!)
        else
          CameraPreview(widget.cameraController!),
        Visibility(
          visible: true,
          child: CustomPaint(
            painter: PosePainter(
              points:  inferenceResultsImage?['point'] ??inferenceResults?['point'] ??[],
              ratio: _ratio,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModelPainter extends StatelessWidget {
  const _ModelPainter({
    required this.customPainter,
    super.key,
  });

  final CustomPainter customPainter;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: customPainter,
    );
  }
}