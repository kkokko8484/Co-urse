import 'package:flutter/material.dart';
import 'selectable_chip.dart';

class OptionGrid extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final int crossAxisCount;

  const OptionGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 2, right: 4),
      itemCount: options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 10,
        childAspectRatio: 1.9,
      ),
      itemBuilder: (context, index) {
        final option = options[index];

        return SelectableChip(
          key: ValueKey('$option-$index'),
          label: option,
          selected: selected.contains(option),
          onTap: () => onToggle(option),
        );
      },
    );
  }
}

class CustomNoteField extends StatefulWidget {
  final String hintText;
  final int maxLength;
  final ValueChanged<String>? onChanged;

  const CustomNoteField({
    super.key,
    required this.hintText,
    this.maxLength = 20,
    this.onChanged,
  });

  @override
  State<CustomNoteField> createState() => _CustomNoteFieldState();
}

class _CustomNoteFieldState extends State<CustomNoteField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: widget.maxLength,
      onChanged: (value) {
        setState(() {});
        widget.onChanged?.call(value);
      },
      style: const TextStyle(
        fontSize: 13.5,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          fontSize: 12.5,
          color: Colors.black38,
        ),
        counterText:
        '${_controller.text.length}/${widget.maxLength}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}