import 'package:cisco_quiz/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default UI language is Portuguese', () {
    expect(S.pt.isPt, isTrue);
    expect(S.pt.appTitle, 'Cisco Quiz');
    expect(S.pt.pause, 'Pausar');
    expect(S.en.pause, 'Pause');
    expect(S.pt.appTitle.toLowerCase().contains('cricket'), isFalse);
    expect(S.en.appTitle.toLowerCase().contains('cricket'), isFalse);
  });
}
