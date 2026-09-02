import 'package:cisco_quiz/widgets/option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('option exposes a letter-prefixed semantic label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OptionTile(
            index: 1,
            label: 'OSPF',
            selected: true,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('OSPF'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.bySemanticsLabel('B. OSPF'), findsOneWidget);
  });

  testWidgets('revealed option is not tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OptionTile(
            index: 0,
            label: 'RIP',
            selected: true,
            revealed: true,
            isCorrect: false,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('RIP'));
    expect(taps, 0);
  });
}
