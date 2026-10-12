import 'package:cisco_quiz/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing or out-of-range correct is not silently scored as A', () {
    final missing = Question.fromJson({
      'question': 'X',
      'options': ['a', 'b', 'c', 'd'],
    });
    expect(missing.correct, -1);
    expect(missing.isValid, isFalse);
    expect(missing.isCorrect(0), isFalse);

    final oob = Question.fromJson({
      'question': 'X',
      'options': ['a', 'b'],
      'correct': 9,
    });
    expect(oob.correct, 9);
    expect(oob.isValid, isFalse);
    expect(oob.isCorrect(1), isFalse);
  });

  test('numeric correct from JSON num is accepted', () {
    final q = Question.fromJson({
      'question': 'X',
      'options': ['a', 'b', 'c', 'd'],
      'correct': 2.0,
    });
    expect(q.correct, 2);
    expect(q.isValid, isTrue);
    expect(q.isCorrect(2), isTrue);
    expect(q.isCorrect(0), isFalse);
  });

  test('unanswered is not counted as correct', () {
    const q = Question(
      question: 'X',
      options: ['a', 'b'],
      correct: 1,
      explanation: '',
      difficulty: '',
    );
    expect(q.isCorrect(null), isFalse);
  });

  test('parses optional topic from JSON and keeps it on round-trip', () {
    final parsed = Question.fromJson({
      'question': 'X',
      'options': ['a', 'b', 'c', 'd'],
      'correct': 0,
      'topic': 'VLAN',
    });
    expect(parsed.topic, 'VLAN');
    expect(parsed.toJson()['topic'], 'VLAN');
  });
}
