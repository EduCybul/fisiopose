import 'dart:math';
import 'dart:ui';

enum MovementType {
  Flexion_hombro_derecho,
  Flexion_hombro_izquierdo,
  Flexion_codos,
  Abduccion_hombros,
  Flexion_cadera_izquierda,
  Flexion_cadera_derecha,
  Flexion_muneca_derecha,
}

class MovementAngleCalculator {
  final Map<MovementType, List<int>> movementKeypoints = {
    MovementType.Flexion_hombro_derecho: [14,12,24],
    MovementType.Flexion_hombro_izquierdo: [13, 11, 23],
    MovementType.Flexion_codos: [16, 14,12],
    MovementType.Abduccion_hombros: [14, 12, 24],
    MovementType.Flexion_cadera_izquierda: [28, 24, 27],
    MovementType.Flexion_cadera_derecha: [27, 23, 28],
    MovementType.Flexion_muneca_derecha: [18, 16, 14],
  };

  double calculateAngle(List<Offset> keypoints, MovementType movementType) {
    final keypointIndexes = movementKeypoints[movementType]!;

    if (keypointIndexes.length < 3) {
      throw Exception('Requiered keypoints missing');
    }

    final keypoint1 = keypoints[keypointIndexes[0]]!;
    final keypoint2 = keypoints[keypointIndexes[1]]!;
    final keypoint3 = keypoints[keypointIndexes[2]]!;

    final angle = _calculateAngle(keypoint1, keypoint2, keypoint3);
    return angle;

  }

  double _calculateAngle(Offset pointA, Offset pointB, Offset pointC) {
    final vectorBA = Offset(pointA.dx - pointB.dx, pointA.dy - pointB.dy);
    final vectorBC = Offset(pointC.dx - pointB.dx, pointC.dy - pointB.dy);

    final dotProduct = (vectorBA.dx * vectorBC.dx) + (vectorBA.dy * vectorBC.dy);
    final magnitudeBA = sqrt(pow(vectorBA.dx, 2) + pow(vectorBA.dy, 2));
    final magnitudeBC = sqrt(pow(vectorBC.dx, 2) + pow(vectorBC.dy, 2));

    final cosineAngle = dotProduct / (magnitudeBA * magnitudeBC);

    // Clamp the cosine value to the range [-1, 1] to avoid NaN due to floating point errors
    final angleInRadians = acos(cosineAngle.clamp(-1, 1));
    final angleInDegrees = angleInRadians * (180 / pi);

    return angleInDegrees;
  }





}