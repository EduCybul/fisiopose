class Movement {
  final String movementName;
  final List<int> keypoints;
  final int maxAngle;
  final String imagepath;
  final String modelName; // Nombre del modelo TFLite asociado

  Movement({
    required this.movementName,
    required this.keypoints,
    required this.maxAngle,
    required this.imagepath,
    required this.modelName,
  });

  double calculateCompletionPercentage(double currentAngle) {
    return (currentAngle / maxAngle) * 100;
  }

}