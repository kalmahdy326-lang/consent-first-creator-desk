import 'package:flutter_test/flutter_test.dart';
import 'package:consent_first_creator_desk/main.dart';

void main() {
  testWidgets('app displays the local drafting desk', (tester) async {
    await tester.pumpWidget(const CreatorDeskApp(loadFromDisk: false));
    await tester.pumpAndSettle();

    expect(find.text('Consent-First Creator Desk'), findsOneWidget);
    expect(
      find.text('Local-only drafting. Nothing is published automatically.'),
      findsOneWidget,
    );
  });
}
