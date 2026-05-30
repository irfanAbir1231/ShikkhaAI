import '../../data/datasources/note_local_datasource.dart';
import '../../data/datasources/note_remote_datasource.dart';
import '../../data/models/note_model.dart';

/// Repository for saved notes.
///
/// Offline-first: writes/deletes go to Hive immediately. Remote sync is
/// best-effort and failures are swallowed (note remains local).
class NoteRepository {
  NoteRepository(this._local, this._remote);

  final NoteLocalDataSource _local;
  final NoteRemoteDataSource _remote;

  Future<void> saveNote(NoteModel note) async {
    await _local.saveNote(note);
    try {
      final created = await _remote.createNote(note);
      // If backend assigned a new id, store under that id and remove client id.
      if (created.id != note.id) {
        await _local.saveNote(created);
        await _local.deleteNote(note.id);
      }
    } catch (_) {
      // Offline — note stays local; SyncService will retry later.
    }
  }

  Future<List<NoteModel>> getNotes({String? topic}) async {
    try {
      final remote = await _remote.fetchNotes(topic: topic);
      for (final n in remote) {
        await _local.saveNote(n);
      }
      return remote;
    } catch (_) {
      return topic == null
          ? _local.getAllNotes()
          : _local.getNotesByTopic(topic);
    }
  }

  List<NoteModel> getLocalNotes({String? topic}) {
    return topic == null
        ? _local.getAllNotes()
        : _local.getNotesByTopic(topic);
  }

  NoteModel? getNote(String id) => _local.getNote(id);

  Future<NoteModel?> getNoteAsync(String id) async {
    final local = _local.getNote(id);
    if (local != null) return local;

    try {
      final remote = await _remote.fetchNoteById(id);
      await _local.saveNote(remote);
      return remote;
    } catch (_) {
      return null;
    }
  }

  /// Generates an AI-powered study note for a topic, caches it locally.
  Future<NoteModel> generateNote({
    required String topic,
    required String subject,
  }) async {
    final note = await _remote.generateNote(topic: topic, subject: subject);
    await _local.saveNote(note);
    return note;
  }

  Future<void> deleteNote(String id) async {
    await _local.deleteNote(id);
    try {
      await _remote.deleteNote(id);
    } catch (_) {
      // Offline — eventual sync should reconcile.
    }
  }
}
