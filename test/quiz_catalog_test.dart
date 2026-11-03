import 'dart:convert';
import 'dart:io';

import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/models/quiz_catalog.dart';
import 'package:cisco_quiz/models/quiz_session.dart';
import 'package:cisco_quiz/services/bank_parser.dart';
import 'package:cisco_quiz/services/catalog_service.dart';
import 'package:cisco_quiz/services/quiz_filters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _q(
  String prompt, {
  Map<String, dynamic> extra = const {},
}) => {
  'question': prompt,
  'options': ['a', 'b', 'c', 'd'],
  'correct': 1,
  'explanation': 'ok',
  'difficulty': 'Médio',
  ...extra,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled catalog vs bundled bank', () {
    final bank = parseQuestionBank(
      jsonDecode(File('assets/cricket.json').readAsStringSync()),
    );
    final catalog = QuizCatalog.tryParse(
      jsonDecode(File('assets/quiz-catalog.json').readAsStringSync()),
    )!;

    test('has the three cyber exam quizzes and the theme quizzes', () {
      final cyber = catalog.quizzesFor('cyber');
      final exams = cyber.where((q) => q.kind == 'exam').map((q) => q.id);
      expect(exams, containsAll(['ccst-cyber', 'cbrops', 'scor']));
      expect(cyber.where((q) => q.kind == 'topic').length, 8);
      expect(catalog.quizzesFor('ccna'), isEmpty);
    });

    test('catalog counts match the filters over the bundled bank', () {
      final raw = jsonDecode(
        File('assets/quiz-catalog.json').readAsStringSync(),
      ) as Map;
      final byId = {
        for (final q in raw['quizzes'] as List) (q as Map)['id']: q['counts'],
      };
      for (final quiz in catalog.quizzes) {
        for (final lang in const ['pt', 'en']) {
          final n = quiz.apply(bank[quiz.parent]![lang]!).length;
          expect(n, (byId[quiz.id] as Map)[lang], reason: '${quiz.id}/$lang');
          expect(n, greaterThan(0));
        }
      }
    });

    test(
      'exam quizzes partition the cyber pool (no duplicates, none left out)',
      () {
        final pool = bank['cyber']!['pt']!;
        final exams = catalog
            .quizzesFor('cyber')
            .where((q) => q.kind == 'exam');
        final total = exams.fold<int>(0, (n, q) => n + q.apply(pool).length);
        expect(total, pool.length);
        final topics = catalog
            .quizzesFor('cyber')
            .where((q) => q.kind == 'topic');
        expect(
          topics.fold<int>(0, (n, q) => n + q.apply(pool).length),
          pool.length,
        );
      },
    );

    test('classic tracks keep their counts', () {
      expect(bank['ccst']!['pt'], hasLength(227));
      expect(bank['ccna']!['en'], hasLength(238));
      expect(bank['ccnp']!['pt'], hasLength(232));
    });

    test('topic slugs get catalog labels', () {
      registerCatalogTopicLabels(catalog.topicLabels);
      expect(topicLabel('cripto', isPt: true), 'Criptografia e PKI');
      expect(topicLabel('cripto', isPt: false), 'Cryptography and PKI');
      expect(topicLabel('vlan', isPt: true), 'VLAN');
      registerCatalogTopicLabels(const {});
    });
  });

  test('question keeps exam/topic/domain and unknown string fields', () {
    final q = Question.fromJson(
      _q(
        'x',
        extra: {
          'exam': 'scor',
          'topic': 'cripto',
          'domain': '2.1',
          'level': 'L2',
        },
      ),
    );
    expect(q.exam, 'scor');
    expect(q.domain, '2.1');
    expect(q.field('level'), 'L2');
    final back = Question.fromJson(q.toJson());
    expect(back.exam, 'scor');
    expect(back.topic, 'cripto');
    expect(back.field('level'), 'L2');
  });

  test('filter supports any-of lists and multiple fields; malformed entries dropped', () {
    final catalog = QuizCatalog.tryParse({
      'version': '9',
      'tracks': [
        {
          'id': 'iiot',
          'labelPt': 'IIoT industrial',
          'labelEn': 'Industrial IoT',
        },
        'junk',
      ],
      'quizzes': [
        {
          'id': 'ot',
          'kind': 'topic',
          'parent': 'iiot',
          'filter': {
            'topic': ['profinet', 'modbus'],
            'exam': 'iiot',
          },
          'labelPt': 'Protocolos OT',
        },
        {'id': 'nofilter', 'parent': 'iiot'},
        {
          'id': 'ot',
          'parent': 'iiot',
          'filter': {'topic': 'dup'},
        },
      ],
    })!;
    expect(catalog.tracks.single.label(isPt: false), 'Industrial IoT');
    expect(catalog.quizzes, hasLength(1));
    final quiz = catalog.quizzes.single;
    expect(quiz.labelEn, 'Protocolos OT');
    expect(
      quiz.matches(
        Question.fromJson(_q('a', extra: {'topic': 'Modbus', 'exam': 'iiot'})),
      ),
      isTrue,
    );
    expect(
      quiz.matches(Question.fromJson(_q('b', extra: {'topic': 'modbus'}))),
      isFalse,
    );
    expect(
      quiz.matches(
        Question.fromJson(_q('c', extra: {'topic': 'vlan', 'exam': 'iiot'})),
      ),
      isFalse,
    );
    expect(QuizCatalog.tryParse([1, 2]), isNull);
  });

  test('parser keeps extra tracks from a future bank', () {
    final decoded = {
      'ccst': {
        'pt': [_q('a')],
        'en': [],
      },
      'ccna': {'pt': [], 'en': []},
      'ccnp': {'pt': [], 'en': []},
      'cyber': {'pt': [], 'en': []},
      'iiot': {
        'pt': [_q('b'), _q('c')],
        'en': [_q('d')],
      },
      'meta': 'not a track',
    };
    expect(bankHasExpectedShape(decoded), isTrue);
    expect(bankTrackKeys(decoded), ['ccst', 'ccna', 'ccnp', 'cyber', 'iiot']);
    final bank = parseQuestionBank(decoded);
    expect(bank['iiot']!['pt'], hasLength(2));
    expect(bankQuestionCount(bank), 4);
  });

  test('session keeps quizId and label through pause/resume', () {
    final q = Question.fromJson(_q('a', extra: {'exam': 'scor'}));
    final session = QuizSession(
      cert: 'cyber',
      examLang: 'pt',
      questions: [q],
      answers: [null],
      currentIndex: 0,
      timeLeftSeconds: 100,
      showingFeedback: false,
      startedAtMs: 1,
      quizId: 'scor',
      quizLabel: 'CCNP Security SCOR (350-701)',
    );
    final back = QuizSession.fromJson(session.toJson());
    expect(back.quizId, 'scor');
    expect(back.displayTitle((c) => c), 'CCNP Security SCOR (350-701)');
    expect(back.questions.single.exam, 'scor');
    final old = QuizSession.fromJson(
      {...session.toJson()}..remove('quizLabel'),
    );
    expect(old.displayTitle((c) => 'Cyber'), 'Cyber');
  });

  group('CatalogService', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('cisco_catalog_'));
    tearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    String body(String id) => jsonEncode({
      'version': id,
      'tracks': [
        {'id': 'cyber'},
      ],
      'quizzes': [
        {
          'id': id,
          'kind': 'exam',
          'parent': 'cyber',
          'filter': {'exam': id},
          'labelPt': id,
        },
      ],
    });

    test(
      'falls back to the bundled asset, then applies and caches remote',
      () async {
        var calls = 0;
        final client = MockClient((req) async {
          calls++;
          expect(req.url.path, endsWith('/data/quiz-catalog.json'));
          return http.Response.bytes(utf8.encode(body('remote')), 200);
        });
        final service = CatalogService(
          httpClient: client,
          cacheDirectory: dir,
          assetLoader: (_) async => body('bundled'),
        );
        await service.load();
        expect(service.source, 'bundle');
        expect(service.catalog.quizzes.single.id, 'bundled');
        expect(await service.refreshRemote(), isTrue);
        expect(service.catalog.quizzes.single.id, 'remote');
        expect(File('${dir.path}/quiz-catalog.json').existsSync(), isTrue);
        // Same body again: no change.
        expect(await service.refreshRemote(), isFalse);
        expect(calls, 2);

        final reopened = CatalogService(
          cacheDirectory: dir,
          assetLoader: (_) async => body('bundled'),
        );
        await reopened.load();
        expect(reopened.source, 'cache');
        expect(reopened.catalog.quizzes.single.id, 'remote');
      },
    );

    test('bad remote payload keeps the current catalog', () async {
      final client = MockClient((_) async => http.Response('{"oops": 1}', 200));
      final service = CatalogService(
        httpClient: client,
        cacheDirectory: dir,
        assetLoader: (_) async => body('bundled'),
      );
      await service.load();
      expect(await service.refreshRemote(), isFalse);
      expect(service.catalog.quizzes.single.id, 'bundled');
    });

    test('corrupt cache falls back to the bundle', () async {
      File('${dir.path}/quiz-catalog.json').writeAsStringSync('{not json');
      final service = CatalogService(
        cacheDirectory: dir,
        assetLoader: (_) async => body('bundled'),
      );
      await service.load();
      expect(service.source, 'bundle');
    });
  });
}
