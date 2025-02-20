import 'dart:math';

class Common {
  static List<double> xywhToCenter(double x, double y, double w, double h) {
    double centerX = x + w / 2;
    double centerY = y + h / 2;
    return [centerX, centerY];
  }

  static double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
