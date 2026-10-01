import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../services/kakao_local_service.dart';
import '../services/course_api_service.dart';

class SelectedLocation {
  final String displayName;
  final String address;
  final double x;
  final double y;

  const SelectedLocation({
    required this.displayName,
    required this.address,
    required this.x,
    required this.y,
  });
}

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() =>
      _LocationSearchScreenState();
}

class _LocationSearchScreenState
    extends State<LocationSearchScreen> {
  final TextEditingController _controller =
  TextEditingController();

  final KakaoLocalService _kakao =
  KakaoLocalService();

  List<KakaoPlace> _placeResults = [];
  List<KakaoAddress> _addressResults = [];

  bool _loading = false;

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _placeResults = [];
      _addressResults = [];
    });

    try {
      // 1. 장소명/지역명/역명 등을 키워드로 검색
      final placeResults =
      await _kakao.searchKeyword(query);

      if (!mounted) return;

      // 키워드 검색 결과가 있으면 그대로 표시
      if (placeResults.isNotEmpty) {
        setState(() {
          _placeResults = placeResults;
        });
        return;
      }

      // 2. 키워드 결과가 없으면 주소 검색
      final addressResults =
      await _kakao.searchAddress(query);

      if (!mounted) return;

      setState(() {
        _addressResults = addressResults;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '검색하지 못했어요.\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _selectPlace(KakaoPlace place) {
    final location = SelectedLocation(
      displayName: place.name,
      address: place.roadAddressName.isNotEmpty
          ? place.roadAddressName
          : place.addressName,
      x: place.x,
      y: place.y,
    );

    CourseApiServiceLocation.setLocation(
      location,
    );

    Navigator.of(context).pop(location);
  }

  void _selectAddress(KakaoAddress address) {
    final location = SelectedLocation(
      displayName: address.shortName,
      address: address.addressName,
      x: address.x,
      y: address.y,
    );

    CourseApiServiceLocation.setLocation(
      location,
    );

    Navigator.of(context).pop(location);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPlaceResults = _placeResults.isNotEmpty;
    final hasAddressResults = _addressResults.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '만날 장소 선택',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),

            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '주소나 장소를 검색해주세요',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                  ),
                  onPressed: _search,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: CircularProgressIndicator(),
              )
            else if (!hasPlaceResults &&
                !hasAddressResults)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  '주소나 장소를 검색해보세요.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: hasPlaceResults
                      ? _placeResults.length
                      : _addressResults.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // 장소 검색 결과
                    if (hasPlaceResults) {
                      final item =
                      _placeResults[index];

                      final address =
                      item.roadAddressName.isNotEmpty
                          ? item.roadAddressName
                          : item.addressName;

                      return ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 5,
                          ),
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 12,
                              color:
                              AppColors.textSecondary,
                            ),
                          ),
                        ),
                        onTap: () =>
                            _selectPlace(item),
                      );
                    }

                    // 주소 검색 결과
                    final item =
                    _addressResults[index];

                    return ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        item.shortName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Padding(
                        padding:
                        const EdgeInsets.only(
                          top: 5,
                        ),
                        child: Text(
                          item.addressName,
                          style: const TextStyle(
                            fontSize: 12,
                            color:
                            AppColors.textSecondary,
                          ),
                        ),
                      ),
                      onTap: () =>
                          _selectAddress(item),
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