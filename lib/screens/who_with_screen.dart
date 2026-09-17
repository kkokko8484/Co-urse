import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_scaffold.dart';
import 'situation_screen.dart';

class WhoWithScreen extends StatefulWidget {
  final CourseFlowData data;

  const WhoWithScreen({
    super.key,
    required this.data,
  });

  @override
  State<WhoWithScreen> createState() => _WhoWithScreenState();
}

class _WhoWithScreenState extends State<WhoWithScreen> {
  final Set<String> _selected = {};
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              '함께하는 사람을 선택해주세요. (복수 선택 가능)\n',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 2,
                right: 4,
              ),
              itemCount: OptionSets.withWhom.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final option = OptionSets.withWhom[index];
                final selected = _selected.contains(option);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(option);
                        } else {
                          _selected.add(option);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFF0E7)
                            : const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFEF8A43)
                              : const Color(0xFFE0E0E0),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Text(
                              option,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: -11,
                              right: -9,
                              child: Container(
                                width: 25,
                                height: 25,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF8A43),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 2,
              maxLength: 20,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText:
                '기타를 선택하셨나요?\n예) 선배, 교수님, 거래처 등',
                hintMaxLines: 2,
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Colors.black38,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                counterText:
                '${_noteController.text.length}/20',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
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