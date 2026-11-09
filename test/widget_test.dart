import 'package:flutter_test/flutter_test.dart';
import 'package:niusic/main.dart';

void main() {
  testWidgets('Niusic shows home and navigation', (tester) async {
    await tester.pumpWidget(NiusicApp());
    await tester.pump();
    expect(find.text('Niusic'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
  });
}
