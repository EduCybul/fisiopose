class Movement {
  final String movementName;
  final List<int> keypoints;
  final int maxAngle;

  Movement({
    required this.movementName,
    required this.keypoints,
    required this.maxAngle,
  });
}