import 'dart:io';
import 'dart:ui' as ui;

import 'package:cisco_quiz/screens/home_screen.dart';
import 'package:cisco_quiz/screens/quiz_screen.dart';
import 'package:cisco_quiz/screens/track_quizzes_screen.dart';
import 'package:cisco_quiz/services/bank_service.dart';
import 'package:cisco_quiz/services/catalog_service.dart';
import 'package:cisco_quiz/services/progress_store.dart';
import 'package:cisco_quiz/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Set SCREENSHOT_DIR to write PNG renders of the new screens (real fonts).
final _shotDir = Platform.environment['SCREENSHOT_DIR'];

Future<void> _loadFonts() async {
  final base =
      '${Platform.environment['FLUTTER_ROOT'] ?? '/workspace/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  if (!Directory(base).existsSync()) return;
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File('$base/$f').readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  const mono = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf';
  if (File(mono).existsSync()) {
    final loader = FontLoader('monospace')
      ..addFont(
        Future.value(ByteData.sublistView(File(mono).readAsBytesSync())),
      );
    await loader.load();
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = _shotDir;
  if (dir == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot-root')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  late Directory dir;
  late BankService bank;
  late CatalogService catalog;
  late ProgressStore store;

  setUpAll(() async {
    if (_shotDir != null) await _loadFonts();
  });

  Future<void> boot(WidgetTester tester, {String lang = 'pt'}) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      dir = Directory.systemTemp.createTempSync('cisco_home_catalog_');
      store = await ProgressStore.create(dataDir: dir);
      await store.setUiLang(lang);
      bank = BankService(store: store, cacheDirectory: dir);
      await bank.load();
      catalog = CatalogService(cacheDirectory: dir);
      await catalog.load();
    });
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot-root'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _shotDir != null
              ? buildCiscoTheme().copyWith(
                  textTheme: buildCiscoTheme().textTheme.apply(
                    fontFamily: 'Roboto',
                  ),
                )
              : buildCiscoTheme(),
          home: HomeScreen(
            bank: bank,
            store: store,
            catalog: catalog,
            autoUpdate: false,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('cyber card opens exam and theme quizzes from the catalog', (
    tester,
  ) async {
    await boot(tester);
    expect(bank.total, 2000);
    expect(catalog.source, 'bundle');
    final open = find.byKey(const ValueKey('open-quizzes-cyber'));
    await tester.scrollUntilVisible(open, 300);
    await tester.pump();
    final cyberCard = find
        .ancestor(of: open, matching: find.byType(Card))
        .first;
    await tester.ensureVisible(cyberCard);
    Scrollable.ensureVisible(tester.element(cyberCard), alignment: 0.1);
    await tester.pumpAndSettle();
    expect(find.text('Escolher exame ou tema (11 quizzes)'), findsOneWidget);
    // Classic tracks have no catalog quizzes, so no button.
    expect(find.byKey(const ValueKey('open-quizzes-ccna')), findsNothing);
    await tester.ensureVisible(open);
    await _shot(tester, 'quiz130-inicio-cartao-cyber');
    await tester.tap(open);
    await tester.pumpAndSettle();

    expect(find.byType(TrackQuizzesScreen), findsOneWidget);
    expect(find.text('POR EXAME'), findsOneWidget);
    expect(find.text('CCST Cybersecurity (100-160)'), findsOneWidget);
    expect(find.text('303 PT • 303 EN'), findsOneWidget);
    expect(find.text('93 PT • 93 EN'), findsOneWidget);
    await _shot(tester, 'quiz130-quizzes-por-exame');
    Future<void> expectTile(String id, String label, String counts) async {
      final tile = find.byKey(ValueKey('quiz-tile-$id'));
      await tester.scrollUntilVisible(tile, 150);
      await tester.pump();
      expect(
        find.descendant(of: tile, matching: find.text(label)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text(counts)),
        findsOneWidget,
      );
    }

    await expectTile(
      'ccst-cyber',
      'CCST Cybersecurity (100-160)',
      '93 PT • 93 EN',
    );
    await expectTile(
      'cbrops',
      'CyberOps / Cybersecurity Associate (200-201)',
      '111 PT • 111 EN',
    );
    await expectTile('scor', 'CCNP Security SCOR (350-701)', '99 PT • 99 EN');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('quiz-section-topic')),
      150,
    );
    expect(find.text('POR TEMA'), findsOneWidget);
    await expectTile('topic-ameacas', 'Ameaças e ataques', '52 PT • 52 EN');

    final cripto = find.byKey(const ValueKey('quiz-tile-topic-cripto'));
    await tester.scrollUntilVisible(cripto, 150);
    await tester.pump();
    await expectTile('topic-cripto', 'Criptografia e PKI', '16 PT • 16 EN');
    await expectTile(
      'topic-logs-ir',
      'Análise de logs e resposta a incidentes',
      '66 PT • 66 EN',
    );
    await _shot(tester, 'quiz130-quizzes-por-tema');

    // Start SCOR in Portuguese.
    final scor = find.byKey(const ValueKey('quiz-tile-scor'));
    await tester.scrollUntilVisible(scor, -200);
    await tester.pump();
    final startPt = find.descendant(
      of: scor,
      matching: find.byType(FilledButton),
    );
    await tester.runAsync(() async {
      await tester.tap(startPt);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(
      find.textContaining('CCNP Security SCOR (350-701) · PT'),
      findsOneWidget,
    );
    final paused = store.loadPaused();
    expect(paused?.quizId, 'scor');
    expect(paused?.cert, 'cyber');
    expect(paused!.length, 50);
    expect(paused.questions.every((q) => q.exam == 'scor'), isTrue);
    await _shot(tester, 'quiz130-quiz-scor-a-decorrer');
  });

  testWidgets('English UI shows theme labels and topic chips from catalog', (
    tester,
  ) async {
    await boot(tester, lang: 'en');
    expect(find.text('Cryptography and PKI'), findsOneWidget);
    final open = find.byKey(const ValueKey('open-quizzes-cyber'));
    await tester.scrollUntilVisible(open, 300);
    await tester.pump();
    expect(find.text('Choose exam or theme (11 quizzes)'), findsOneWidget);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('BY EXAM'), findsOneWidget);
    expect(
      find.text('CyberOps / Cybersecurity Associate (200-201)'),
      findsOneWidget,
    );
    await _shot(tester, 'quiz130-quizzes-en');
  });
}
