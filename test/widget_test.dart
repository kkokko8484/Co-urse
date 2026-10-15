import 'package:flutter_test/flutter_test.dart';
import 'package:course_app/main.dart';

void main() {
testWidgets('Co:urse 앱이 정상적으로 실행된다', (WidgetTester tester) async {
await tester.pumpWidget(const CourseApp());

expect(find.text('Co:urse'), findsOneWidget);
});
}
