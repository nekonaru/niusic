import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niusic/main.dart';

void main() {
  testWidgets('Niusic shows home and navigation', (tester) async {
    await tester.pumpWidget(NiusicApp());
    await tester.pump();
    expect(find.text('Niusic'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Niusic uses bottom bar on narrow screens', (tester) async {
    tester.view.physicalSize = Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NiusicApp());
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Niusic uses rail on wide screens', (tester) async {
    tester.view.physicalSize = Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NiusicApp());
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
