import 'package:flutter/material.dart';
import 'selectable_chip.dart';

/// 3열 그리드로 선택지를 보여주는 위젯 (누구와 함께 / 어떤 상황 화면에서 사용)
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
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 38,
      ),
      itemBuilder: (context, index) {
        final option = options[index];
        return SelectableChip(
          label: option,
          selected: selected.contains(option),
          onTap: () => onToggle(option),
        );
      },
    );
  }
}

/// 기타 항목 입력용 텍스트 필드 (0/20 글자수 표시)
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
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: widget.maxLength,
      onChanged: (value) {
        setState(() {});
        widget.onChanged?.call(value);
      },
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(fontSize: 12.5, color: Colors.black38),
        counterText: '${_controller.text.length}/${widget.maxLength}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
