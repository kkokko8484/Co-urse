import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/models.dart';
import 'course_recommend_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  final CourseFlowData data;
  const AnalyzingScreen({super.key, required this.data});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  static const List<String> _steps = [
    '취향 수집 완료',
    '선호 음식 분석 중',
    '활동 조합 분석 중',
    '최적 코스 탐색 중',
    '추천 코스 생성 중',
  ];

  int _current = 0;

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    for (int i = 0; i <= _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _current = i);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CourseRecommendScreen(data: widget.data, isAlternate: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF9F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                '취향을 분석중이에요',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                '잠시만 기다려주세요!',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2F3A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF35C4B8), size: 64),
              ),
              const Spacer(flex: 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '분석 진행 상황',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),
                    for (int i = 0; i < _steps.length; i++) _buildStepRow(i),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Text('TIP  ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFFE0A030))),
                    Expanded(
                      child: Text(
                        '정확한 추천을 위해 다양한 취향을 선택할수록 좋아요!',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(int index) {
    final bool done = index < _current;
    final bool active = index == _current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (done)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20)
          else if (active)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else
            Icon(Icons.circle_outlined, color: AppColors.textTertiary.withOpacity(0.5), size: 20),
          const SizedBox(width: 12),
          Text(
            _steps[index],
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: done || active ? FontWeight.w700 : FontWeight.w500,
              color: done || active ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
