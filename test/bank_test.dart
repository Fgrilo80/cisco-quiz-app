import 'dart:convert';
import 'dart:io';

import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/services/bank_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled snapshot matches expected cert/lang counts', () {
    final file = File('assets/cricket.json');
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<Map>());
    final data = decoded as Map;
    const expected = {'ccst': 171, 'ccna': 177, 'ccnp': 172};
    for (final cert in expected.keys) {
      for (final lang in const ['pt', 'en']) {
        final list = (data[cert] as Map)[lang] as List;
        expect(list, hasLength(expected[cert]));
        final first = Question.fromJson(
          Map<String, dynamic>.from(list.first as Map),
        );
        expect(first.question, isNotEmpty);
        expect(first.options, isNotEmpty);
        expect(first.isValid, isTrue);
      }
    }
    final parsed = parseQuestionBank(decoded);
    expect(bankQuestionCount(parsed), 1040);
  });

  test('parses optional cli field', () {
    final q = Question.fromJson({
      'question': 'Ping?',
      'options': ['a', 'b', 'c', 'd'],
      'correct': 1,
      'explanation': 'ok',
      'difficulty': 'Fácil',
      'cli': 'PC> ping 8.8.8.8',
    });
    expect(q.hasCli, isTrue);
    expect(q.cli, contains('ping'));
  });

  test('drops empty and malformed questions instead of scoring them', () {
    final decoded = {
      'ccst': {
        'pt': [
          {
            'question': 'Valid?',
            'options': ['a', 'b', 'c', 'd'],
            'correct': 2,
            'explanation': 'ok',
            'difficulty': 'Fácil',
          },
          {
            'question': '',
            'options': ['a', 'b'],
            'correct': 0,
          },
          {'question': 'No options', 'options': [], 'correct': 0},
          {
            'question': 'Out of range',
            'options': ['a', 'b'],
            'correct': 9,
          },
          {
            'question': 'Missing correct',
            'options': ['a', 'b', 'c'],
          },
        ],
        'en': [],
      },
      'ccna': {'pt': [], 'en': []},
      'ccnp': {'pt': [], 'en': []},
    };
    final parsed = parseQuestionBank(decoded);
    expect(parsed['ccst']!['pt'], hasLength(1));
    expect(parsed['ccst']!['pt']!.single.correct, 2);
    expect(bankQuestionCount(parsed), 1);
  });

  test('corrupt or empty cache is not used', () {
    expect(shouldUseCachedBank(null), isFalse);
    expect(shouldUseCachedBank('nope'), isFalse);
    expect(shouldUseCachedBank({'ccst': {}}), isFalse);
    expect(
      shouldUseCachedBank({
        'ccst': {'pt': [], 'en': []},
        'ccna': {'pt': [], 'en': []},
        'ccnp': {'pt': [], 'en': []},
      }),
      isFalse,
    );
    expect(
      shouldUseCachedBank({
        'ccst': {
          'pt': [
            {
              'question': 'OK',
              'options': ['a', 'b'],
              'correct': 1,
            },
          ],
          'en': [],
        },
        'ccna': {'pt': [], 'en': []},
        'ccnp': {'pt': [], 'en': []},
      }),
      isTrue,
    );
  });
}
