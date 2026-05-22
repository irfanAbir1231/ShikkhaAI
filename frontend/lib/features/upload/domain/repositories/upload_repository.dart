import 'package:image_picker/image_picker.dart';

import '../../data/models/handwritten_models.dart';
import '../../data/services/mock_ocr_service.dart';
import 'upload_repository_interface.dart';

/// Concrete upload repository using image_picker and mock OCR service.
class UploadRepository implements UploadRepositoryInterface {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pickImage({required bool fromCamera}) async {
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    return picked?.path;
  }

  @override
  Future<HandwrittenEvaluation> processHandwritten(
    HandwrittenUpload upload,
  ) =>
      MockOcrService.processHandwritten(upload);

  @override
  Future<HandwrittenEvaluation?> getEvaluation(String evaluationId) async {
    // In-memory cache only for mock
    return null;
  }

  @override
  Future<List<HandwrittenEvaluation>> getRecentEvaluations() async {
    // Mock: return empty list for now
    return [];
  }

  @override
  Future<void> deleteUpload(String uploadId) async {
    // No-op for mock
  }
}
