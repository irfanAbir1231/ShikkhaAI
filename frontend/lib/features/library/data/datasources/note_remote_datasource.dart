import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../models/note_model.dart';

/// Remote data source for Notes API.
///
/// Backend contract:
/// - `POST /notes` → returns created [NoteModel] in envelope `data`
/// - `GET /notes?topic=...&source=...` → returns list of [NoteModel]
/// - `DELETE /notes/{id}` → 204 / success envelope
class NoteRemoteDataSource {
  NoteRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<NoteModel> createNote(NoteModel note) async {
    final data = await _apiService.post(
      ApiConstants.notes,
      data: note.toJson(),
    );
    return NoteModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<NoteModel>> fetchNotes({String? topic, String? source}) async {
    final data = await _apiService.get(
      ApiConstants.notes,
      queryParameters: {
        if (topic != null) 'topic': topic,
        if (source != null) 'source': source,
      },
    );
    return (data as List<dynamic>)
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoteModel> fetchNoteById(String id) async {
    final data = await _apiService.get(
      '${ApiConstants.notes}/$id',
    );
    return NoteModel.fromJson(data as Map<String, dynamic>);
  }

  /// Generates an AI-powered study note for a topic.
  Future<NoteModel> generateNote({
    required String topic,
    required String subject,
  }) async {
    final data = await _apiService.post(
      '${ApiConstants.notes}/generate',
      data: {
        'topic': topic,
        'subject': subject,
      },
    );
    return NoteModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteNote(String id) async {
    await _apiService.delete('${ApiConstants.notes}/$id');
  }
}
