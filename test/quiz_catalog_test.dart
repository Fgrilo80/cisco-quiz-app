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
          final n = catalogQuizPool(
            quiz,
            lang,
            (t, l) => bank[t]?[l] ?? const [],
          ).length;
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
      expect(bank['ccst']!['pt'], hasLength(268));
      expect(bank['ccna']!['en'], hasLength(239));
      expect(bank['ccnp']!['pt'], hasLength(274));
    });

    test('every catalog track and quiz parent exists in the bundled bank', () {
      expect(catalog.version, '4.3.0');
      expect(
        catalog.trackOrder,
        containsAll([
          'ccst',
          'ccna',
          'ccnp',
          'cyber',
          'ccstit',
          'iiot',
          'field',
          'automation',
          'wireless',
          'sdx',
          'dc',
          'collab',
        ]),
      );
      for (final t in catalog.trackOrder) {
        expect(bank[t]?['pt'], isNotEmpty, reason: t);
      }
      for (final q in catalog.quizzes) {
        for (final t in q.sourceTracks) {
          expect(bank.containsKey(t), isTrue, reason: '${q.id} → $t');
        }
      }
      expect(catalog.quizzes, hasLength(21));
    });

    test('alsoFrom pulls tagged ccna/ccnp questions into phase 3 exams', () {
      final wlsd = catalog.quiz('wlsd')!;
      expect(wlsd.parent, 'wireless');
      expect(wlsd.alsoFrom, ['ccna', 'ccnp']);
      List<Question> qs(String t, String l) => bank[t]?[l] ?? const [];
      final own = wlsd.apply(qs('wireless', 'pt')).length;
      final pool = catalogQuizPool(wlsd, 'pt', qs);
      expect(pool.length, 65);
      expect(pool.length, greaterThan(own));
      final extra = pool.skip(own).toList();
      expect(extra.every((q) => q.exam == 'wlsd'), isTrue);
      final ccnaIds = qs('ccna', 'pt').map((q) => q.id).toSet();
      expect(extra.any((q) => ccnaIds.contains(q.id)), isTrue);
      // Track-level pools stay as they are (no alsoFrom without a quiz).
      expect(qs('wireless', 'pt'), hasLength(125));
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

  test('alsoFrom parsing ignores junk, parent and duplicates', () {
    final quiz = CatalogQuiz.fromJson({
      'id': 'x',
      'kind': 'exam',
      'parent': 'wireless',
      'filter': {'exam': 'wlsd'},
      'labelPt': 'X',
      'alsoFrom': ['ccna', 'wireless', 'ccna', 3, '', 'ccnp'],
    })!;
    expect(quiz.alsoFrom, ['ccna', 'ccnp']);
    expect(quiz.sourceTracks, ['wireless', 'ccna', 'ccnp']);
    final noAlso = CatalogQuiz.fromJson({
      'id': 'y',
      'parent': 'cyber',
      'filter': {'exam': 'scor'},
    })!;
    expect(noAlso.alsoFrom, isEmpty);
  });

  test('catalogQuizPool merges alsoFrom matches once, own track first', () {
    final bank = parseQuestionBank({
      'ccst': {'pt': [], 'en': []},
      'ccna': {
        'pt': [
          _q('shared', extra: {'exam': 'wlsd'}),
          _q('ccna only', extra: {'exam': 'wlsd'}),
          _q('other', extra: {'exam': 'ccna'}),
        ],
        'en': [],
      },
      'ccnp': {'pt': [], 'en': []},
      'wireless': {
        'pt': [
          _q('own', extra: {'exam': 'wlsd'}),
          _q('shared', extra: {'exam': 'wlsd'}),
          _q('wlsi', extra: {'exam': 'wlsi'}),
        ],
        'en': [],
      },
    });
    final quiz = CatalogQuiz.fromJson({
      'id': 'wlsd',
      'parent': 'wireless',
      'filter': {'exam': 'wlsd'},
      'alsoFrom': ['ccna', 'missing'],
    })!;
    final pool = catalogQuizPool(quiz, 'pt', (t, l) => bank[t]?[l] ?? const []);
    expect(pool.map((q) => q.question), ['own', 'shared', 'ccna only']);
    expect(
      catalogQuizPool(quiz, 'en', (t, l) => bank[t]?[l] ?? const []),
      isEmpty,
    );
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
