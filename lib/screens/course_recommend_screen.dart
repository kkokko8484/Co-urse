import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../data/dummy_data.dart';
import '../models/models.dart';
import '../widgets/primary_button.dart';
import 'course_detail_screen.dart';
import 'save_schedule_screen.dart';

RecommendedCourse resolveCourse(CourseFlowData data, bool isAlternate) {
  if (data.mode == FlowMode.solo) {
    return isAlternate ? soloAltCourse : soloPrimaryCourse;
  }
  return isAlternate ? friendsAltCourse(data.namesLabel) : friendsPrimaryCourse(data.namesLabel);
}

class CourseRecommendScreen extends StatefulWidget {
  final CourseFlowData data;
  final bool isAlternate;

  const CourseRecommendScreen({
    super.key,
    required this.data,
    required this.isAlternate,
  });

  @override
  State<CourseRecommendScreen> createState() => _CourseRecommendScreenState();
}

class _CourseRecommendScreenState extends State<CourseRecommendScreen> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final course = resolveCourse(widget.data, widget.isAlternate);

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
        title: const Text(
          '추천 코스',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _liked ? Icons.favorite : Icons.favorite_border,
              color: _liked ? AppColors.primary : AppColors.textPrimary,
            ),
            onPressed: () => setState(() => _liked = !_liked),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: AppColors.textPrimary),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('공유 링크가 복사되었어요'), duration: Duration(seconds: 1)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                course.headerTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Text(
                  '추천 코스',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < course.stops.length; i++)
                      _StopTile(
                        index: i,
                        stop: course.stops[i],
                        isLast: i == course.stops.length - 1,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CourseDetailScreen(
                              data: widget.data,
                              course: course,
                              stopIndex: i,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 15, color: AppColors.textTertiary),
                            const SizedBox(width: 6),
                            Text(
                              '예상 소요시간 ${course.estimatedDuration}',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: '다시 추천',
                      outlined: true,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => CourseRecommendScreen(
                              data: widget.data,
                              isAlternate: !widget.isAlternate,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: '이 코스로 확정하기',
                      success: true,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SaveScheduleScreen(data: widget.data, course: course),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  final int index;
  final CourseStop stop;
  final bool isLast;
  final VoidCallback onTap;

  const _StopTile({
    required this.index,
    required this.stop,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppColors.chipBorder),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stop.category}  ${stop.timeRange}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.chipBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: stop.color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(stop.icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stop.info,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
