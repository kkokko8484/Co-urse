import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/models.dart';
import '../widgets/primary_button.dart';
import 'course_recommend_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseFlowData data;
  final RecommendedCourse course;
  final int stopIndex;

  const CourseDetailScreen({
    super.key,
    required this.data,
    required this.course,
    required this.stopIndex,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _liked = false;

  PlaceDetail get _detail {
    if (widget.stopIndex == widget.course.detailStopIndex) {
      return widget.course.detail;
    }
    final stop = widget.course.stops[widget.stopIndex];
    return PlaceDetail(
      category: stop.info,
      rating: 4.3,
      reviewCount: 56,
      description: '${stop.category}을(를) 즐기기 좋은 인기 장소예요.\n합리적인 가격과 편안한 분위기를 갖추고 있어요.',
      hours: '매일 10:00 ~ 22:00',
      menu: '대표 메뉴 정보',
      priceRange: '1인 10,000원 ~ 20,000원',
      facility: '화장실, 와이파이',
      icon: stop.icon,
      color: stop.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.course.stops[widget.stopIndex];
    final detail = _detail;

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
          '코스 상세',
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
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: detail.color,
                        child: Icon(detail.icon, color: Colors.white, size: 64),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      stop.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.category,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFB020), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          detail.rating.toString(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${detail.reviewCount})',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        detail.description,
                        style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(icon: Icons.schedule, label: '영업시간', value: detail.hours),
                    _InfoRow(icon: Icons.restaurant_menu, label: '대표 메뉴', value: detail.menu),
                    _InfoRow(icon: Icons.sell_outlined, label: '가격대', value: detail.priceRange),
                    _InfoRow(icon: Icons.wc, label: '편의시설', value: detail.facility),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: '코스에 추가하기',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => CourseRecommendScreen(data: widget.data, isAlternate: true),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
