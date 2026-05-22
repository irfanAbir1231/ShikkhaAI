import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/organisms/app_bar.dart';
import '../../../../common_widgets/organisms/error_state.dart';
import '../../../../routing/route_names.dart';
import '../providers/handwritten_upload_provider.dart';
import '../widgets/image_preview_card.dart';
import '../widgets/image_source_selector.dart';
import '../widgets/ocr_processing_animation.dart';

/// Handwritten upload flow: select → preview → process.
class HandwrittenUploadScreen extends ConsumerStatefulWidget {
  const HandwrittenUploadScreen({super.key});

  @override
  ConsumerState<HandwrittenUploadScreen> createState() =>
      _HandwrittenUploadScreenState();
}

class _HandwrittenUploadScreenState
    extends ConsumerState<HandwrittenUploadScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(handwrittenUploadProvider);
    final notifier = ref.read(handwrittenUploadProvider.notifier);

    // Navigate to result when completed
    if (state.isCompleted && state.evaluation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push(
          '${RouteNames.upload}/${RouteNames.uploadHandwritten}/result/${state.evaluation!.id}',
        );
        notifier.clear();
      });
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Handwritten Evaluation',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            notifier.clear();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(state, notifier),
        ),
      ),
    );
  }

  Widget _buildBody(
    HandwrittenUploadState state,
    HandwrittenUploadNotifier notifier,
  ) {
    if (state.isSelecting) {
      return ImageSourceSelector(
        onCamera: () => notifier.pickImage(fromCamera: true),
        onGallery: () => notifier.pickImage(fromCamera: false),
      );
    }

    if (state.isPreview && state.upload?.imagePath != null) {
      return SingleChildScrollView(
        key: const ValueKey('preview'),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ImagePreviewCard(
              imagePath: state.upload!.imagePath!,
              onRetake: notifier.retake,
              onSubmit: notifier.submit,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    if (state.isProcessing) {
      return const OcrProcessingAnimation(key: ValueKey('processing'));
    }

    if (state.hasError) {
      return ErrorState(
        key: const ValueKey('error'),
        message: state.error ?? 'Something went wrong',
        onRetry: () {
          if (state.upload?.imagePath != null) {
            notifier.submit();
          } else {
            notifier.retake();
          }
        },
      );
    }

    return const SizedBox.shrink();
  }
}
