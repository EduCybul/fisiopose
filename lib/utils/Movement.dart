class Movement {
  final String movementName;
  final List<int> keypoints;
  final int maxAngle;
  final String imagepath;

  Movement({
    required this.movementName,
    required this.keypoints,
    required this.maxAngle,
    required this.imagepath,
  });

  double calculateCompletionPercentage(double currentAngle) {
    return (currentAngle / maxAngle) * 100;
  }

}