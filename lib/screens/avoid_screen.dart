import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../widgets/primary_button.dart';
import '../widgets/selectable_chip.dart';
import '../widgets/step_scaffold.dart';
import 'analyzing_screen.dart';

/// 마지막 취향 선택 단계: 피하고 싶은 요소가 있나요?
class AvoidScreen extends StatefulWidget {
  final CourseFlowData data;
  final int stepIndex;
  final int stepTotal;

  const AvoidScreen({
    super.key,
    required this.data,
    required this.stepIndex,
    required this.stepTotal,
  });

  @override
  State<AvoidScreen> createState() => _AvoidScreenState();
}

class _AvoidScreenState extends State<AvoidScreen> {
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.data.avoidFactors);
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
              '피하고 싶은 요소가 있나요?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '해당되는 항목을 선택해주세요',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ...OptionSets.avoidFactors.map(
              (label) => SelectableCheckRow(
                label: label,
                selected: _selected.contains(label),
                onTap: () => setState(() {
                  _selected.contains(label) ? _selected.remove(label) : _selected.add(label);
                }),
              ),
            ),
          ],
        ),
      ),
      bottomButton: PrimaryButton(
        label: '취향 분석하기',
        onPressed: () {
          widget.data
            ..avoidFactors.clear()
            ..avoidFactors.addAll(_selected);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AnalyzingScreen(data: widget.data)),
          );
        },
      ),
    );
  }
}
