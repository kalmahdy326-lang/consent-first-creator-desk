import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:consent_first_creator_desk/main.dart';

void main() {
  testWidgets('app displays the local drafting desk', (tester) async {
    final supportDirectory =
        await Directory.systemTemp.createTemp('creator-desk-widget-test-');
    addTearDown(() async {
      if (await supportDirectory.exists()) {
        await supportDirectory.delete(recursive: true);
      }
    });

    await tester.pumpWidget(CreatorDeskApp(
      supportDirectoryProvider: () async => supportDirectory,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Consent-First Creator Desk'), findsOneWidget);
    expect(find.text('Local-only drafting. Nothing is published automatically.'),
        findsOneWidget);
  });
}
