import 'package:flutter_test/flutter_test.dart';

import 'package:ecosync_cropguard/app.dart';

void main() {
  testWidgets('EcoSyncApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoSyncApp());
    await tester.pump();
  });
}
