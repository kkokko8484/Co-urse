import 'package:flutter/material.dart';
import '../app_colors.dart';

/// 취향 선택 단계 화면들에서 공통으로 쓰는 뼈대
/// (뒤로가기 + "취향 선택 n/m" 타이틀 + 스크롤 가능한 본문 + 하단 고정 버튼)
class StepScaffold extends StatelessWidget {
  final String title;
  final int stepIndex;
  final int stepTotal;
  final Widget body;
  final Widget bottomButton;

  const StepScaffold({
    super.key,
    required this.title,
    required this.stepIndex,
    required this.stepTotal,
    required this.body,
    required this.bottomButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$stepIndex / $stepTotal',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: body,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: bottomButton,
        ),
      ),
    );
  }
}
