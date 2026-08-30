import 'dart:convert';
import 'dart:io';

import 'package:cisco_quiz/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled snapshot matches expected cert/lang counts', () {
    final file = File('assets/cricket.json');
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<Map>());
    final data = decoded as Map;
    const expected = {
      'ccst': 163,
      'ccna': 157,
      'ccnp': 160,
    };
    for (final cert in expected.keys) {
      for (final lang in const ['pt', 'en']) {
        final list = (data[cert] as Map)[lang] as List;
        expect(list, hasLength(expected[cert]));
        final first = Question.fromJson(Map<String, dynamic>.from(list.first as Map));
        expect(first.question, isNotEmpty);
        expect(first.options, isNotEmpty);
      }
    }
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
}
