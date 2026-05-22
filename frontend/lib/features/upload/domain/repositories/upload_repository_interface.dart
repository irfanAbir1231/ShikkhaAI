import '../../data/models/handwritten_models.dart';

/// Abstract contract for upload and evaluation operations.
abstract class UploadRepositoryInterface {
  /// Pick an image from camera or gallery.
  /// Returns the file path, or null if cancelled.
  Future<String?> pickImage({required bool fromCamera});

  /// Process a handwritten upload through OCR + AI evaluation.
  Future<HandwrittenEvaluation> processHandwritten(HandwrittenUpload upload);

  /// Get a cached evaluation by ID.
  Future<HandwrittenEvaluation?> getEvaluation(String evaluationId);

  /// Get recent uploads / evaluations.
  Future<List<HandwrittenEvaluation>> getRecentEvaluations();

  /// Delete an upload and its evaluation.
  Future<void> deleteUpload(String uploadId);
}
