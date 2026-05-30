import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';

/// Remote data source for Study Companion RAG endpoints.
///
/// Backend contract: `POST /study-companion/ask` returns `{ response, sources, ... }`
/// inside the standard envelope `data` field.
class StudyCompanionRemoteDataSource {
  StudyCompanionRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Sends a question to the RAG-powered study companion.
  ///
  /// [pdfContext] is optional extracted text from a user-uploaded PDF that
  /// the backend cross-references with the curriculum book in ChromaDB.
  Future<Map<String, dynamic>> ask({
    required int studentId,
    required String message,
    required String mode,
    required String subject,
    required String classLevel,
    String? pdfContext,
  }) async {
    final data = await _apiService.post(
      ApiConstants.studyCompanionAsk,
      data: {
        'student_id': studentId,
        'message': message,
        'mode': mode,
        'subject': subject,
        'class_level': classLevel,
        if (pdfContext != null) 'pdf_context': pdfContext,
      },
    );
    return data as Map<String, dynamic>;
  }

  /// Fetches AI-generated notes for a specific topic.
  Future<Map<String, dynamic>> topicNotes({
    required int studentId,
    required String topic,
    required String subject,
    required String classLevel,
  }) async {
    final data = await _apiService.post(
      ApiConstants.studyCompanionTopicNotes,
      data: {
        'student_id': studentId,
        'topic': topic,
        'subject': subject,
        'class_level': classLevel,
      },
    );
    return data as Map<String, dynamic>;
  }
}
