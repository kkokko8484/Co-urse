import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../widgets/option_grid.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_scaffold.dart';
import 'preference_screen.dart';

/// 두 흐름 공통 단계: 어떤 상황인가요? (단일 선택)
class SituationScreen extends StatefulWidget {
  final CourseFlowData data;
  final int stepIndex;
  final int stepTotal;

  const SituationScreen({
    super.key,
    required this.data,
    required this.stepIndex,
    required this.stepTotal,
  });

  @override
  State<SituationScreen> createState() => _SituationScreenState();
}

class _SituationScreenState extends State<SituationScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.situation;
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: '취향 선택',
      stepIndex: widget.stepIndex,
      stepTotal: widget.stepTotal,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              '어떤 상황인가요?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '상황을 선택하면 더 잘 맞는 코스를 추천해드려요!',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            OptionGrid(
              options: OptionSets.situations,
              selected: _selected == null ? {} : {_selected!},
              onToggle: (o) => setState(() {
                _selected = (_selected == o) ? null : o;
              }),
            ),
            const SizedBox(height: 16),
            const CustomNoteField(
              hintText: '기타를 선택하셨나요?\n예: 부모님, 생신, 동호회 모임 등',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomButton: PrimaryButton(
        label: '다음',
        onPressed: _selected == null
            ? null
            : () {
                widget.data.situation = _selected;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PreferenceScreen(
                      data: widget.data,
                      stepIndex: widget.stepIndex + 1,
                      stepTotal: widget.stepTotal,
                    ),
                  ),
                );
              },
      ),
    );
  }
}
