import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/handwritten_models.dart';
import '../../domain/repositories/upload_repository.dart';

/// Repository provider.
final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) => UploadRepository(),
);

/// Central state for the handwritten upload flow.
class HandwrittenUploadState {
  const HandwrittenUploadState({
    this.upload,
    this.evaluation,
    this.error,
  });

  final HandwrittenUpload? upload;
  final HandwrittenEvaluation? evaluation;
  final String? error;

  UploadStatus get status => upload?.status ?? UploadStatus.selecting;
  bool get isSelecting => status == UploadStatus.selecting;
  bool get isPreview => status == UploadStatus.preview;
  bool get isProcessing => status == UploadStatus.processing;
  bool get isCompleted => status == UploadStatus.completed;
  bool get hasError => status == UploadStatus.error;

  HandwrittenUploadState copyWith({
    HandwrittenUpload? upload,
    HandwrittenEvaluation? evaluation,
    String? error,
  }) {
    return HandwrittenUploadState(
      upload: upload ?? this.upload,
      evaluation: evaluation ?? this.evaluation,
      error: error ?? this.error,
    );
  }
}

/// Manages the handwritten upload lifecycle.
class HandwrittenUploadNotifier extends StateNotifier<HandwrittenUploadState> {
  HandwrittenUploadNotifier(this._repository)
      : super(const HandwrittenUploadState());

  final UploadRepository _repository;

  Future<void> pickImage({required bool fromCamera}) async {
    try {
      final path = await _repository.pickImage(fromCamera: fromCamera);
      if (path == null) return;

      final upload = HandwrittenUpload(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: path,
        uploadedAt: DateTime.now(),
        status: UploadStatus.preview,
      );
      state = state.copyWith(upload: upload, error: null);
    } catch (e) {
      state = state.copyWith(
        upload: state.upload?.copyWith(status: UploadStatus.error),
        error: 'Failed to pick image: $e',
      );
    }
  }

  void retake() {
    state = const HandwrittenUploadState();
  }

  Future<void> submit() async {
    final upload = state.upload;
    if (upload == null || upload.imagePath == null) return;

    state = state.copyWith(
      upload: upload.copyWith(status: UploadStatus.processing),
      error: null,
    );

    try {
      final evaluation = await _repository.processHandwritten(state.upload!);
      state = state.copyWith(
        upload: state.upload!.copyWith(status: UploadStatus.completed),
        evaluation: evaluation,
      );
    } catch (e) {
      state = state.copyWith(
        upload: state.upload!.copyWith(status: UploadStatus.error),
        error: 'Evaluation failed: $e',
      );
    }
  }

  void clear() {
    state = const HandwrittenUploadState();
  }
}

/// Provider for the handwritten upload flow.
final handwrittenUploadProvider =
    StateNotifierProvider<HandwrittenUploadNotifier, HandwrittenUploadState>(
  (ref) => HandwrittenUploadNotifier(ref.watch(uploadRepositoryProvider)),
);
