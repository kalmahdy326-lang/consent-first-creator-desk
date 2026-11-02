import 'package:flutter_test/flutter_test.dart';
import 'package:consent_first_creator_desk/main.dart';

void main() {
  testWidgets('app displays the local drafting desk', (tester) async {
    await tester.pumpWidget(const CreatorDeskApp());
    await tester.pumpAndSettle();
    expect(find.text('Consent-First Creator Desk'), findsOneWidget);
  });
}
