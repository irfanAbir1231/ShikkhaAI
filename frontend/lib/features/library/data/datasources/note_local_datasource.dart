import 'package:hive/hive.dart';

import '../models/note_model.dart';

/// Hive-backed local cache for saved notes.
class NoteLocalDataSource {
  NoteLocalDataSource(this._box);

  final Box<String> _box;

  Future<void> saveNote(NoteModel note) async {
    await _box.put(note.id, note.toJsonString());
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  NoteModel? getNote(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return NoteModel.fromJsonString(raw);
  }

  List<NoteModel> getAllNotes() {
    final notes = _box.values
        .map((raw) => NoteModel.fromJsonString(raw))
        .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  List<NoteModel> getNotesByTopic(String topic) {
    return getAllNotes().where((n) => n.topic == topic).toList();
  }
}
