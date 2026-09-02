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
    expect(S.pt.reviewWeak, 'Rever fracas');
    expect(S.en.reviewWeak, 'Review weak');
    expect(S.pt.difficultyEasy, 'Fácil');
    expect(S.en.difficultyEasy, 'Easy');
    expect(S.pt.retryMissed.toLowerCase().contains('cricket'), isFalse);
  });

  test('new UI strings stay Cisco Quiz and never Cricket', () {
    for (final ui in [S.pt, S.en]) {
      expect(ui.appTitle, 'Cisco Quiz');
      expect(ui.filterTitle.toLowerCase().contains('cricket'), isFalse);
      expect(ui.retryMissed.toLowerCase().contains('cricket'), isFalse);
      expect(ui.statsTitle.toLowerCase().contains('cricket'), isFalse);
      expect(ui.reviewMode.toLowerCase().contains('cricket'), isFalse);
      expect(ui.versionBadge.contains('1.2'), isTrue);
    }
  });
}
