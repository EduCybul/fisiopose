import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../services/model_inference_service.dart';
import '../../../services/service_locator.dart';
import '../utils/MovementAngleCalculator.dart';
import 'pose_painter.dart';

class ModelCameraPreview extends StatefulWidget {
  const ModelCameraPreview({
    super.key,
    required this.cameraController,
    required this.movement,
    required this.draw,
    this.imageData,
  });

  final CameraController? cameraController;
  final String movement;
  final bool draw;
  final Uint8List? imageData;

  @override
  ModelCameraPreviewState createState() => ModelCameraPreviewState();
}

class ModelCameraPreviewState extends State<ModelCameraPreview> {
  late double _ratio;
  Map<String, dynamic>? inferenceResultsImage;
  Map<String, dynamic>? inferenceResults;
  final MovementAngleCalculator _angleCalculator= MovementAngleCalculator();

  @override
  void initState() {
    super.initState();
    inferenceResults = locator<ModelInferenceService>().inferenceResults ?? {};
  }

  void updateInferenceResults(List<dynamic> pointss) {
    print('Received points: $pointss' );
    setState(() {
      inferenceResults = locator<ModelInferenceService>().inferenceResults ?? {};
      print('inferenceResultsImage:  $inferenceResults');
    });
  }


  List<Offset> convertPoints (Map<String,dynamic> inferenceResult) {
      List<Offset> points = [];
      if(inferenceResult['point'] == null) return points;
      for (var entry in inferenceResult['point']) {
        double x = entry['x'];
        double y = entry['y'];
        points.add(Offset(x, y));
      }
      return points;
    }

  double? _calculateAngleForMovement(String movementName, List<Offset> points) {
    MovementType? movementType;
    switch (movementName.toLowerCase()) {
      case 'flexion hombro derecho':
        movementType = MovementType.Flexion_hombro_derecho;
        break;
      case 'flexion hombro izquierdo':
        movementType = MovementType.Flexion_hombro_izquierdo;
        break;
      case 'flexion codo':
        movementType = MovementType.Flexion_codos;
        break;
      case 'abduccion hombro':
        movementType = MovementType.Abduccion_hombros;
        break;
      case 'flexion cadera izquierda':
        movementType = MovementType.Flexion_cadera_izquierda;
        break;
      case 'flexion cadera derecha':
        movementType = MovementType.Flexion_cadera_derecha;
        break;
      case 'flexion muneca derecha':
        movementType = MovementType.Flexion_muneca_derecha;
        break;


    // Add more cases as needed
    }

    if (movementType == null) return null;

    try {

      return _angleCalculator.calculateAngle(points,movementType);
    } catch (e) {
      print('Error calculating angle: $e');
      return null;
    }
  }


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
    final points =  convertPoints((inferenceResultsImage ?? inferenceResults ?? [] ) as Map<String,dynamic>);


    //final keypoints = _extractKeypoints(inferenceResults);

    double? angle;
    if(points != null){
      angle = _calculateAngleForMovement(widget.movement, points);
    }

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
              points:  points,//inferenceResults?['point'] ?? [],
              ratio: _ratio,
            ),
          ),
        ),
        if(angle != null)
            Positioned(
              top: 10,
              left: 10,
              child: Text(
                'Angle: ${angle.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
