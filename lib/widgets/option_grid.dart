import 'package:flutter/material.dart';
import 'selectable_chip.dart';

/// 선택지를 그리드 형태로 보여주는 공통 위젯
class OptionGrid extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// 한 줄에 몇 개를 보여줄지
  final int crossAxisCount;

  /// 버튼 가로/세로 비율
  ///
  /// SituationScreen → 1.15 (큰 버튼)
  /// PreferenceScreen → 1.75 (작고 납작한 버튼)
  final double childAspectRatio;

  const OptionGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.15,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,

      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,

        // 가로 간격
        crossAxisSpacing: 10,

        // 세로 간격
        mainAxisSpacing: 10,

        // 버튼 비율
        childAspectRatio: childAspectRatio,
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

/// 기타 항목 입력용 텍스트 필드
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
      maxLines: 2,

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
          height: 1.4,
        ),

        contentPadding: const EdgeInsets.fromLTRB(
          14,
          9,
          14,
          3,
        ),

        counterText:
        '${_controller.text.length}/${widget.maxLength}',

        counterStyle: const TextStyle(
          fontSize: 12,
          color: Colors.black45,
          height: 1,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFD9D9D9),
            width: 1,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFD9D9D9),
            width: 1,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
      ),
    );
  }
}