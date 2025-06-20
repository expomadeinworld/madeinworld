// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:madeinworld_app/main.dart';

void main() {
  testWidgets('Made in World app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MadeInWorldApp());

    // Verify that our app loads with the main screen
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('地点'), findsOneWidget);
    expect(find.text('消息'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    // Verify that the home screen content is present
    expect(find.text('卢加诺'), findsOneWidget);
    expect(find.text('热门推荐'), findsOneWidget);
  });
}
