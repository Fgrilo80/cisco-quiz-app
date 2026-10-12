import 'dart:convert';
import 'dart:io';

import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/models/quiz_session.dart';
import 'package:cisco_quiz/services/bank_parser.dart';
import 'package:cisco_quiz/services/quiz_filters.dart';
import 'package:cisco_quiz/services/quiz_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Question q({
  required String text,
  String difficulty = 'Fácil',
  String? topic,
}) => Question(
  question: text,
  options: const ['a', 'b', 'c', 'd'],
  correct: 1,
  explanation: 'e',
  difficulty: difficulty,
  topic: topic,
);

void main() {
  test('Fácil and Easy map to the same difficulty key', () {
    expect(canonicalDifficulty('Fácil'), kDifficultyEasy);
    expect(canonicalDifficulty('Easy'), kDifficultyEasy);
    expect(canonicalDifficulty('Médio'), kDifficultyMedium);
    expect(canonicalDifficulty('Medium'), kDifficultyMedium);
    expect(canonicalDifficulty('Difícil'), kDifficultyHard);
    expect(canonicalDifficulty('Hard'), kDifficultyHard);
    expect(difficultyOf(q(text: 'x', difficulty: 'Easy')), kDifficultyEasy);
  });

  test('JSON topic field wins over keywords', () {
    final withField = Question.fromJson({
      'question': 'Something about OSPF areas',
      'options': ['a', 'b', 'c', 'd'],
      'correct': 1,
      'explanation': 'ok',
      'difficulty': 'Easy',
      'topic': 'VLAN',
    });
    expect(topicOf(withField), 'vlan');
  });

  test('without a topic field, keywords tag VLAN and OSPF', () {
    final vlan = q(text: 'Qual VLAN nativa num trunk 802.1Q?');
    final ospf = q(text: 'What is OSPF area 0 called?');
    final other = q(text: 'Qual a cor do logótipo?');
    expect(topicOf(vlan), 'vlan');
    expect(topicOf(ospf), 'ospf');
    expect(topicOf(other), kOtherTopic);
  });

  test('filters by difficulty and topic and reports remaining count', () {
    final pool = [
      q(text: 'VLAN fácil', difficulty: 'Fácil'),
      q(text: 'VLAN média', difficulty: 'Médio'),
      q(text: 'OSPF fácil', difficulty: 'Easy'),
      q(text: 'OSPF difícil', difficulty: 'Hard'),
    ];
    final easy = applyFilters(pool, difficulty: kDifficultyEasy);
    expect(easy, hasLength(2));
    expect(easy.every((e) => difficultyOf(e) == kDifficultyEasy), isTrue);

    final vlan = applyFilters(pool, topic: 'vlan');
    expect(vlan, hasLength(2));
    expect(vlan.every((e) => topicOf(e) == 'vlan'), isTrue);

    expect(remainingCount(pool, difficulty: kDifficultyHard, topic: 'ospf'), 1);
    expect(remainingCount(pool), 4);
  });

  test('filtered exam uses 50 or the whole pool if smaller', () {
    final small = [q(text: 'VLAN 10'), q(text: 'VLAN 20'), q(text: 'VLAN 30')];
    expect(filteredExamCount(small.length), 3);
    final picked = pickQuestions(pool: small, seenIds: {}, count: quizLength);
    expect(picked, hasLength(3));
    expect(filteredExamCount(80), 50);
    expect(filteredExamCount(0), 0);
  });

  test('bundled bank: easy filter is a strict subset with remaining count', () {
    final file = File('assets/cricket.json');
    expect(file.existsSync(), isTrue);
    final parsed = parseQuestionBank(jsonDecode(file.readAsStringSync()));
    final pool = parsed['ccna']!['en']!;
    expect(pool, isNotEmpty);
    final easy = applyFilters(pool, difficulty: kDifficultyEasy);
    expect(easy.length, lessThan(pool.length));
    expect(easy, isNotEmpty);
    expect(easy.every((e) => difficultyOf(e) == kDifficultyEasy), isTrue);
    final vlan = applyFilters(pool, topic: 'vlan');
    expect(vlan, isNotEmpty);
    expect(vlan.length, lessThan(pool.length));
    expect(remainingCount(pool, topic: 'vlan'), vlan.length);
    expect(filteredExamCount(vlan.length) <= 50, isTrue);
    expect(filteredExamCount(vlan.length) <= vlan.length, isTrue);
  });
}
