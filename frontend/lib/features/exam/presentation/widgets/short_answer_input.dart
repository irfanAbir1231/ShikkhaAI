import 'package:flutter/material.dart';

import '../../../../common_widgets/molecules/app_text_field.dart';
import '../../../../theme/color_tokens.dart';

/// Multi-line text input for short answer questions.
class ShortAnswerInput extends StatefulWidget {
  const ShortAnswerInput({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.maxLength = 500,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLength;

  @override
  State<ShortAnswerInput> createState() => _ShortAnswerInputState();
}

class _ShortAnswerInputState extends State<ShortAnswerInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(ShortAnswerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _controller,
          hint: 'Type your answer here...',
          maxLines: 6,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_controller.text.length}/${widget.maxLength}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
