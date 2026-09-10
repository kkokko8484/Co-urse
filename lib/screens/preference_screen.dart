import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../widgets/option_grid.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_scaffold.dart';
import 'avoid_screen.dart';

/// 두 흐름 공통 단계: 어떤 취향을 선호하시나요?
/// (음식 취향 / 분위기 / 우선순위 / 예산 범위)
class PreferenceScreen extends StatefulWidget {
  final CourseFlowData data;
  final int stepIndex;
  final int stepTotal;

  const PreferenceScreen({
    super.key,
    required this.data,
    required this.stepIndex,
    required this.stepTotal,
  });

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  final Set<String> _food = {};
  final Set<String> _mood = {};
  final Set<String> _priority = {};
  String? _budget;

  static const int _maxPriority = 3;

  @override
  void initState() {
    super.initState();
    _food.addAll(widget.data.foodTypes);
    _mood.addAll(widget.data.moods);
    _priority.addAll(widget.data.priorities);
    _budget = widget.data.budget;
  }

  bool get _canProceed =>
      _food.isNotEmpty && _mood.isNotEmpty && _priority.isNotEmpty && _budget != null;

  void _togglePriority(String option) {
    setState(() {
      if (_priority.contains(option)) {
        _priority.remove(option);
      } else if (_priority.length < _maxPriority) {
        _priority.add(option);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('우선순위는 최대 3개까지 선택할 수 있어요'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
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
              '어떤 취향을 선호하시나요?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '선호하는 취향을 선택하면\n더 딱 맞는 코스를 추천해드려요!',
              style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: '음식 취향', hint: '(복수 선택 가능)'),
            OptionGrid(
              options: OptionSets.foodTypes,
              selected: _food,
              crossAxisCount: 4,
              onToggle: (o) => setState(() {
                _food.contains(o) ? _food.remove(o) : _food.add(o);
              }),
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: '분위기', hint: '(복수 선택 가능)'),
            OptionGrid(
              options: OptionSets.moods,
              selected: _mood,
              crossAxisCount: 4,
              onToggle: (o) => setState(() {
                _mood.contains(o) ? _mood.remove(o) : _mood.add(o);
              }),
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: '우선순위', hint: '(최대 3개 선택)'),
            OptionGrid(
              options: OptionSets.priorities,
              selected: _priority,
              crossAxisCount: 4,
              onToggle: _togglePriority,
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: '예산 범위', hint: '(1인 기준)'),
            OptionGrid(
              options: OptionSets.budgets,
              selected: _budget == null ? {} : {_budget!},
              crossAxisCount: 4,
              onToggle: (o) => setState(() => _budget = (_budget == o) ? null : o),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomButton: PrimaryButton(
        label: '다음',
        onPressed: _canProceed
            ? () {
                widget.data
                  ..foodTypes.clear()
                  ..foodTypes.addAll(_food)
                  ..moods.clear()
                  ..moods.addAll(_mood)
                  ..priorities.clear()
                  ..priorities.addAll(_priority)
                  ..budget = _budget;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AvoidScreen(
                      data: widget.data,
                      stepIndex: widget.stepIndex + 1,
                      stepTotal: widget.stepTotal,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
