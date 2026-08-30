import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/services/quiz_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Question q(String text) => Question(
      question: text,
      options: const ['a', 'b', 'c', 'd'],
      correct: 1,
      explanation: 'e',
      difficulty: 'Fácil',
    );

void main() {
  test('prefers unseen questions until the pool is exhausted', () {
    final pool = [for (var i = 0; i < 10; i++) q('Q$i')];
    final seen = {for (var i = 0; i < 8; i++) pool[i].id};
    final picked = pickQuestions(pool: pool, seenIds: seen, count: 2);
    expect(picked.map((e) => e.question).toSet(), {'Q8', 'Q9'});
  });

  test('reuses seen items only after the pool is exhausted', () {
    final pool = [for (var i = 0; i < 4; i++) q('Q$i')];
    final seen = {for (final item in pool) item.id};
    final picked = pickQuestions(pool: pool, seenIds: seen, count: 3);
    expect(picked, hasLength(3));
    expect(picked.every((e) => seen.contains(e.id)), isTrue);
  });

  test('does not exceed the pool size', () {
    final pool = [q('only')];
    final picked = pickQuestions(pool: pool, seenIds: {}, count: 50);
    expect(picked, hasLength(1));
  });
}
