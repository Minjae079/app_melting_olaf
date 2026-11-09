// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:temp_alert_app/main.dart';

void main() {
  testWidgets('앱 기본 화면을 표시한다', (tester) async {
    await tester.pumpWidget(const TempAlertApp());

    expect(find.text('PIPE GUARD'), findsOneWidget);
    expect(find.text('안녕하세요!'), findsOneWidget);
  });
}
