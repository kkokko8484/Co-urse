# Co:urse API 설정

기존 UI 파일은 수정하지 않고 API 연결에 필요한 파일만 추가했습니다.

## 카카오 REST API

실행할 때 REST API 키를 `--dart-define`으로 전달합니다.

```bash
flutter run --dart-define=KAKAO_REST_API_KEY=여기에_카카오_REST_API_키
```

키를 코드나 GitHub에 저장하지 않습니다.

## 네이버

네이버 검색 API를 사용할 경우:

```bash
flutter run --dart-define=KAKAO_REST_API_KEY=카카오키 --dart-define=NAVER_CLIENT_ID=네이버클라이언트ID --dart-define=NAVER_CLIENT_SECRET=네이버클라이언트시크릿
```

현재 실제 코스 검색은 카카오 Local API를 사용합니다. 네이버 서비스 코드는 추가되어 있으며 키가 없으면 호출하지 않습니다.

## 변경 범위

기존 UI 위젯/화면은 수정하지 않았습니다.

추가:
- `lib/config/api_keys.dart`
- `lib/services/kakao_local_service.dart`
- `lib/services/naver_search_service.dart`
- `lib/services/course_api_service.dart`
- `lib/screens/api_course_recommend_screen.dart`
- `API_SETUP.md`

API 연결을 위한 기존 코드의 최소 변경:
- `pubspec.yaml`: `http` 의존성 추가
- `lib/screens/analyzing_screen.dart`: API 추천 화면으로 이동하도록 import/화면 클래스만 변경

기존 `preference_screen.dart`, `option_grid.dart`, `selectable_chip.dart`, `who_with_screen.dart`, `situation_screen.dart`, `avoid_screen.dart`, `course_recommend_screen.dart` 등 UI 파일은 변경하지 않았습니다.
