import 'package:flutter/material.dart';

import '../../../../common_widgets/animations/animated_scale_tap.dart';
import '../../../../common_widgets/molecules/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/dashboard_models.dart';
import 'section_header.dart';

/// Horizontal scrollable weak subjects with progress bars.
class WeakSubjectsSection extends StatelessWidget {
  const WeakSubjectsSection({super.key, required this.subjects});

  final List<WeakSubject> subjects;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: AppLocalizations.of(context).dashWeakSubjects),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return SizedBox(
                width: 160,
                child: AnimatedScaleTap(
                  onTap: () {},
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: subject.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            subject.icon,
                            color: subject.color,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          subject.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: subject.accuracy / 100,
                            minHeight: 6,
                            backgroundColor: subject.color.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context).homeAccuracyPercent(
                              subject.accuracy.toInt().toString()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
