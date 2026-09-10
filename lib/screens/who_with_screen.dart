import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../widgets/option_grid.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_scaffold.dart';
import 'situation_screen.dart';

/// 상황 기반(솔로) 흐름의 1/4 단계: 누구와 함께하나요?
class WhoWithScreen extends StatefulWidget {
  final CourseFlowData data;
  const WhoWithScreen({super.key, required this.data});

  @override
  State<WhoWithScreen> createState() => _WhoWithScreenState();
}

class _WhoWithScreenState extends State<WhoWithScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: '취향 선택',
      stepIndex: 1,
      stepTotal: 4,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              '누구와 함께하나요?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '함께하는 사람을 선택해주세요. (복수 선택 가능)',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            OptionGrid(
              options: OptionSets.withWhom,
              selected: _selected,
              onToggle: (o) => setState(() {
                _selected.contains(o) ? _selected.remove(o) : _selected.add(o);
              }),
            ),
            const SizedBox(height: 16),
            CustomNoteField(
              hintText: '기타를 선택하셨나요?\n예: 부모님, 형제, 동호회 모임 등',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomButton: PrimaryButton(
        label: '다음',
        onPressed: _selected.isEmpty
            ? null
            : () {
                widget.data.withWhom
                  ..clear()
                  ..addAll(_selected);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SituationScreen(
                      data: widget.data,
                      stepIndex: 2,
                      stepTotal: 4,
                    ),
                  ),
                );
              },
      ),
    );
  }
}
