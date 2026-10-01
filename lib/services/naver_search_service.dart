import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

class NaverLocalPlace {
  final String title;
  final String category;
  final String address;
  final String roadAddress;
  final String link;
  final String mapx;
  final String mapy;

  const NaverLocalPlace({
    required this.title,
    required this.category,
    required this.address,
    required this.roadAddress,
    required this.link,
    required this.mapx,
    required this.mapy,
  });
}

class NaverSearchService {
  static const _endpoint =
      'https://openapi.naver.com/v1/search/local.json';

  Future<List<NaverLocalPlace>> searchLocal(
    String query, {
    int display = 5,
  }) async {
    if (ApiKeys.naverClientId.isEmpty ||
        ApiKeys.naverClientSecret.isEmpty) {
      return [];
    }

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'query': query,
        'display': display.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'X-Naver-Client-Id': ApiKeys.naverClientId,
        'X-Naver-Client-Secret': ApiKeys.naverClientSecret,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Naver Search API error: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (json['items'] as List<dynamic>? ?? []);

    String clean(String value) {
      return value
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"');
    }

    return items.map((item) {
      final data = item as Map<String, dynamic>;

      return NaverLocalPlace(
        title: clean(data['title']?.toString() ?? ''),
        category: data['category']?.toString() ?? '',
        address: data['address']?.toString() ?? '',
        roadAddress:
            data['roadAddress']?.toString() ?? '',
        link: data['link']?.toString() ?? '',
        mapx: data['mapx']?.toString() ?? '',
        mapy: data['mapy']?.toString() ?? '',
      );
    }).toList();
  }
}
