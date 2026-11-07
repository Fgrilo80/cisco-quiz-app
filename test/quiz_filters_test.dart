import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/models/quiz_session.dart';
import 'package:cisco_quiz/services/quiz_filters.dart';
import 'package:cisco_quiz/services/quiz_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Question q(String text, {String difficulty = 'Fácil'}) => Question(
  question: text,
  options: const ['a', 'b', 'c', 'd'],
  correct: 1,
  explanation: 'e',
  difficulty: difficulty,
);

void main() {
  test('normalizes PT and EN difficulty labels', () {
    expect(canonicalDifficulty('Fácil'), kDifficultyEasy);
    expect(canonicalDifficulty('Easy'), kDifficultyEasy);
    expect(canonicalDifficulty('Médio'), kDifficultyMedium);
    expect(canonicalDifficulty('Medium'), kDifficultyMedium);
    expect(canonicalDifficulty('Difícil'), kDifficultyHard);
    expect(canonicalDifficulty('Hard'), kDifficultyHard);
    expect(canonicalDifficulty(''), '');
  });

  test('filters by difficulty and topic without inventing questions', () {
    final pool = [
      q('Which VLAN is native?', difficulty: 'Fácil'),
      q('OSPF area 0', difficulty: 'Médio'),
      q('Hard BGP path selection', difficulty: 'Difícil'),
      q('Easy BGP neighbor', difficulty: 'Easy'),
    ];
    final vlanEasy = applyFilters(
      pool,
      difficulty: kDifficultyEasy,
      topic: 'vlan',
    );
    expect(vlanEasy, hasLength(1));
    expect(vlanEasy.single.question, contains('VLAN'));

    final bgp = applyFilters(pool, topic: 'bgp');
    expect(bgp.map((e) => e.question).toSet(), {
      'Hard BGP path selection',
      'Easy BGP neighbor',
    });
  });

  test('filtered exams are 50 or fewer', () {
    final pool = [for (var i = 0; i < 80; i++) q('VLAN $i')];
    final filtered = applyFilters(pool, topic: 'vlan');
    expect(filtered, hasLength(80));
    final n = filteredExamCount(filtered.length);
    expect(n, quizLength);
    final picked = pickQuestions(pool: filtered, seenIds: {}, count: n);
    expect(picked, hasLength(50));
  });

  test('small filtered pool uses every matching bank item', () {
    final pool = [q('Only VLAN question')];
    final filtered = applyFilters(pool, topic: 'vlan');
    expect(filteredExamCount(filtered.length), 1);
    final picked = pickQuestions(
      pool: filtered,
      seenIds: {},
      count: filteredExamCount(filtered.length),
    );
    expect(picked, hasLength(1));
    expect(picked.single.question, 'Only VLAN question');
  });

  test('session timer scales down for short filtered sets', () {
    expect(sessionSecondsFor(50), quizSeconds);
    expect(sessionSecondsFor(10), 540);
    expect(sessionSecondsFor(1), 180);
  });
}
