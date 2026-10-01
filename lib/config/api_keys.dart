class ApiKeys {
  ApiKeys._();

  static const kakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );

  static const naverClientId = String.fromEnvironment(
    'NAVER_CLIENT_ID',
  );

  static const naverClientSecret = String.fromEnvironment(
    'NAVER_CLIENT_SECRET',
  );
}
