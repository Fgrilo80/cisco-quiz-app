import 'dart:convert';
import 'dart:io';

import 'package:cisco_quiz/services/bank_parser.dart';
import 'package:cisco_quiz/services/bank_service.dart';
import 'package:cisco_quiz/services/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _bankBody(String prompt) {
  return jsonEncode({
    'ccst': {
      'pt': [
        {
          'question': prompt,
          'options': ['a', 'b', 'c', 'd'],
          'correct': 1,
          'explanation': 'ok',
          'difficulty': 'Fácil',
        },
      ],
      'en': <Object>[],
    },
    'ccna': {'pt': <Object>[], 'en': <Object>[]},
    'ccnp': {'pt': <Object>[], 'en': <Object>[]},
    'cyber': {'pt': <Object>[], 'en': <Object>[]},
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hash inequality with equal totals sets updateAvailable', () async {
    final dir = Directory.systemTemp.createTempSync('cisco_bank_hash_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final localBody = _bankBody('Same count, old distractors');
    final remoteBody = _bankBody('Same count, new distractors');
    final localBytes = utf8.encode(localBody);
    final remoteBytes = utf8.encode(remoteBody);
    expect(bankContentHash(localBytes), isNot(bankContentHash(remoteBytes)));

    final store = await ProgressStore.create(dataDir: dir);
    await File('${dir.path}/cricket.json').writeAsBytes(localBytes);
    final bank = BankService(
      store: store,
      cacheDirectory: dir,
      httpClient: MockClient((request) async {
        return http.Response.bytes(remoteBytes, 200);
      }),
    );
    await bank.load();
    final localTotal = bank.total;

    final probe = await bank.probeRemote();
    expect(probe, isNotNull);
    expect(probe!.total, localTotal);
    expect(bank.total, localTotal);
    expect(bank.updateAvailable, isTrue);
    expect(probe.contentHash, bankContentHash(remoteBytes));
  });

  test('equal hash does not set updateAvailable', () async {
    final dir = Directory.systemTemp.createTempSync('cisco_bank_same_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final body = _bankBody('Unchanged distractors');
    final bytes = utf8.encode(body);
    final store = await ProgressStore.create(dataDir: dir);
    await store.setLastBankHash(bankContentHash(bytes));
    await File('${dir.path}/cricket.json').writeAsBytes(bytes);
    final bank = BankService(
      store: store,
      cacheDirectory: dir,
      httpClient: MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      }),
    );
    await bank.load();

    final probe = await bank.probeRemote();
    expect(probe, isNotNull);
    expect(probe!.total, bank.total);
    expect(probe.contentHash, store.lastBankHash);
    expect(bank.updateAvailable, isFalse);

    final applied = await bank.checkAndAutoRefresh();
    expect(applied, isNull);
    expect(bank.updateAvailable, isFalse);
    expect(bank.questions('ccst', 'pt').single.question, 'Unchanged distractors');
  });

  test('bootstrap auto-applies when hashes differ and stores the hash', () async {
    final dir = Directory.systemTemp.createTempSync('cisco_bank_apply_');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final localBytes = utf8.encode(_bankBody('Before'));
    final remoteBody = _bankBody('After');
    final remoteBytes = utf8.encode(remoteBody);
    final store = await ProgressStore.create(dataDir: dir);
    await File('${dir.path}/cricket.json').writeAsBytes(localBytes);
    final bank = BankService(
      store: store,
      cacheDirectory: dir,
      httpClient: MockClient((request) async {
        return http.Response.bytes(remoteBytes, 200);
      }),
    );
    await bank.load();
    expect(bank.total, 1);

    final applied = await bank.checkAndAutoRefresh();
    expect(applied, 1);
    expect(bank.total, 1);
    expect(bank.updateAvailable, isFalse);
    expect(bank.questions('ccst', 'pt').single.question, 'After');
    expect(store.lastBankHash, bankContentHash(remoteBytes));
    expect(bankHasExpectedShape(jsonDecode(remoteBody)), isTrue);
  });
}
