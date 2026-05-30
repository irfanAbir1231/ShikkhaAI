import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../data/datasources/note_local_datasource.dart';
import '../../data/datasources/note_remote_datasource.dart';
import '../../data/models/note_model.dart';
import '../../domain/repositories/note_repository.dart';

final noteLocalDataSourceProvider = Provider<NoteLocalDataSource>((ref) {
  final box = Hive.box<String>(StorageKeys.savedNotesBox);
  return NoteLocalDataSource(box);
});

final noteRemoteDataSourceProvider = Provider<NoteRemoteDataSource>((ref) {
  return NoteRemoteDataSource();
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(
    ref.watch(noteLocalDataSourceProvider),
    ref.watch(noteRemoteDataSourceProvider),
  );
});

/// Bump to refresh notes list (e.g. after save/delete).
final notesRefreshProvider = StateProvider<int>((ref) => 0);

final notesProvider = FutureProvider<List<NoteModel>>((ref) async {
  ref.watch(notesRefreshProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getNotes();
});

final notesByTopicProvider =
    FutureProvider.family<List<NoteModel>, String>((ref, topic) async {
  ref.watch(notesRefreshProvider);
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getNotes(topic: topic);
});

/// Fetches a single note by ID (local first, remote fallback).
final noteDetailProvider = FutureProvider.family<NoteModel?, String>(
  (ref, id) async {
    final repo = ref.watch(noteRepositoryProvider);
    return repo.getNoteAsync(id);
  },
);
