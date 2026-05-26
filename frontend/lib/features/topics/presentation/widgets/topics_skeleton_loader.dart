import 'package:flutter/material.dart';

import '../../../../common_widgets/atoms/shimmer_box.dart';

/// Shimmer placeholder while topics data is loading.
class TopicsSkeletonLoader extends StatelessWidget {
  const TopicsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress card skeleton
          const ShimmerBox(height: 120, borderRadius: 16),
          const SizedBox(height: 16),
          // Filter chips skeleton
          const Row(
            children: [
              ShimmerBox(width: 60, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 80, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 70, height: 32, borderRadius: 16),
            ],
          ),
          const SizedBox(height: 16),
          // Subject cards skeleton
          ...List.generate(4, (_) => const _SubjectCardSkeleton()),
        ],
      ),
    );
  }
}

class _SubjectCardSkeleton extends StatelessWidget {
  const _SubjectCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              ShimmerBox(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 16),
                    SizedBox(height: 8),
                    ShimmerBox(width: 80, height: 12),
                  ],
                ),
              ),
              ShimmerBox(width: 36, height: 36, borderRadius: 18),
            ],
          ),
        ),
      ),
    );
  }
}
