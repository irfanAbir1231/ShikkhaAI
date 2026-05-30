import 'package:flutter/material.dart';

import '../../../../common_widgets/molecules/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/color_tokens.dart';

/// Structured sub-part inputs for Creative Question (CQ).
class CqAnswerInput extends StatefulWidget {
  const CqAnswerInput({
    super.key,
    required this.subParts,
    required this.answers,
    required this.onChanged,
  });

  final List<String> subParts;
  final Map<String, String> answers;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<CqAnswerInput> createState() => _CqAnswerInputState();
}

class _CqAnswerInputState extends State<CqAnswerInput> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final part in widget.subParts)
        part: TextEditingController(text: widget.answers[part] ?? ''),
    };
  }

  @override
  void didUpdateWidget(CqAnswerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final part in widget.subParts) {
      final controller = _controllers[part];
      final newValue = widget.answers[part] ?? '';
      if (controller != null && controller.text != newValue) {
        controller.text = newValue;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notifyChange() {
    final result = <String, String>{};
    for (final entry in _controllers.entries) {
      result[entry.key] = entry.value.text;
    }
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final part in widget.subParts) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  part,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: _controllers[part],
                  hint: AppLocalizations.of(context).cqAnswerHint(part),
                  maxLines: 4,
                  onChanged: (_) => _notifyChange(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
