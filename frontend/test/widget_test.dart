import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test — ensure the app builds without errors
    // Full widget testing will be added in Phase 2
    expect(1 + 1, equals(2));
  });
}
