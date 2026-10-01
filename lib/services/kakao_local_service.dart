import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

class KakaoPlace {
  final String id;
  final String name;
  final String categoryName;
  final String addressName;
  final String roadAddressName;
  final String phone;
  final String placeUrl;
  final double x;
  final double y;
  final int distance;

  const KakaoPlace({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.addressName,
    required this.roadAddressName,
    required this.phone,
    required this.placeUrl,
    required this.x,
    required this.y,
    required this.distance,
  });

  factory KakaoPlace.fromJson(
      Map<String, dynamic> json,
      ) {
    return KakaoPlace(
      id: json['id']?.toString() ?? '',
      name: json['place_name']?.toString() ?? '',
      categoryName:
      json['category_name']?.toString() ?? '',
      addressName:
      json['address_name']?.toString() ?? '',
      roadAddressName:
      json['road_address_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      placeUrl:
      json['place_url']?.toString() ?? '',
      x: double.tryParse(
        json['x']?.toString() ?? '',
      ) ??
          0,
      y: double.tryParse(
        json['y']?.toString() ?? '',
      ) ??
          0,
      distance: int.tryParse(
        json['distance']?.toString() ?? '',
      ) ??
          0,
    );
  }
}

class KakaoAddress {
  final String addressName;
  final String roadAddressName;
  final double x;
  final double y;

  const KakaoAddress({
    required this.addressName,
    required this.roadAddressName,
    required this.x,
    required this.y,
  });

  String get shortName {
    final road = roadAddressName.trim();

    if (road.isNotEmpty) {
      final parts = road.split(' ');

      if (parts.length >= 3) {
        return '${parts[0]} ${parts[1]} ${parts[2]}';
      }

      return road;
    }

    final address = addressName.trim();
    final parts = address.split(' ');

    if (parts.length >= 3) {
      return '${parts[0]} ${parts[1]} ${parts[2]}';
    }

    return address;
  }
}

class KakaoLocalService {
  static const String _baseUrl =
      'https://dapi.kakao.com/v2/local';

  Map<String, String> get _headers => {
    'Authorization':
    'KakaoAK ${ApiKeys.kakaoRestApiKey}',
  };

  Future<List<KakaoPlace>> searchKeyword(
      String query, {
        int size = 15,
        double? x,
        double? y,
        int? radius,
      }) async {
    final params = <String, String>{
      'query': query,
      'size': size.toString(),
    };

    if (x != null && y != null) {
      params['x'] = x.toString();
      params['y'] = y.toString();
    }

    if (radius != null) {
      params['radius'] = radius.toString();
    }

    final uri = Uri.parse(
      '$_baseUrl/search/keyword.json',
    ).replace(
      queryParameters: params,
    );

    debugPrint('==============================');
    debugPrint('카카오 키워드 검색');
    debugPrint('검색어: $query');
    debugPrint('URL: $uri');

    final response = await http.get(
      uri,
      headers: _headers,
    );

    debugPrint(
      '상태코드: ${response.statusCode}',
    );
    debugPrint(
      '응답: ${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Kakao Local API error: '
            '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        '카카오 API 응답 형식이 올바르지 않습니다.',
      );
    }

    final documents =
    decoded['documents'];

    if (documents is! List) {
      debugPrint('documents가 List가 아닙니다.');
      return [];
    }

    debugPrint(
      '검색 결과 개수: ${documents.length}',
    );

    final results = documents
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => KakaoPlace.fromJson(item),
    )
        .toList();

    for (final item in results) {
      debugPrint(
        '장소: ${item.name} / '
            '${item.roadAddressName.isNotEmpty ? item.roadAddressName : item.addressName}',
      );
    }

    debugPrint('==============================');

    return results;
  }

  Future<List<KakaoAddress>> searchAddress(
      String query,
      ) async {
    final uri = Uri.parse(
      '$_baseUrl/search/address.json',
    ).replace(
      queryParameters: {
        'query': query,
        'size': '10',
      },
    );

    debugPrint('==============================');
    debugPrint('카카오 주소 검색');
    debugPrint('검색어: $query');
    debugPrint('URL: $uri');

    final response = await http.get(
      uri,
      headers: _headers,
    );

    debugPrint(
      '상태코드: ${response.statusCode}',
    );
    debugPrint(
      '응답: ${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Kakao Address API error: '
            '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        '카카오 주소 API 응답 형식이 올바르지 않습니다.',
      );
    }

    final documents =
    decoded['documents'];

    if (documents is! List) {
      return [];
    }

    final results = documents.map((item) {
      final data =
      item as Map<String, dynamic>;

      final road =
      data['road_address']
      as Map<String, dynamic>?;

      final address =
      data['address']
      as Map<String, dynamic>?;

      return KakaoAddress(
        addressName:
        address?['address_name']
            ?.toString() ??
            data['address_name']
                ?.toString() ??
            '',
        roadAddressName:
        road?['address_name']
            ?.toString() ??
            '',
        x: double.tryParse(
          data['x']?.toString() ?? '',
        ) ??
            0,
        y: double.tryParse(
          data['y']?.toString() ?? '',
        ) ??
            0,
      );
    }).toList();

    debugPrint(
      '주소 검색 결과 개수: ${results.length}',
    );
    debugPrint('==============================');

    return results;
  }
}