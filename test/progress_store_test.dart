import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/models/quiz_session.dart';
import 'package:cisco_quiz/services/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seen set is per certification and language', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.create();
    await store.addSeen('ccna', 'pt', ['id-a', 'id-b']);
    expect(store.loadSeen('ccna', 'pt'), {'id-a', 'id-b'});
    expect(store.loadSeen('ccna', 'en'), isEmpty);
    expect(store.loadSeen('ccst', 'pt'), isEmpty);
  });

  test('paused session restores pending selection', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.create();
    const question = Question(
      question: 'OSPF area?',
      options: ['0', '1', '2', '3'],
      correct: 0,
      explanation: 'backbone',
      difficulty: 'Médio',
    );
    final session = QuizSession(
      cert: 'ccna',
      examLang: 'pt',
      questions: const [question],
      answers: [null],
      currentIndex: 0,
      timeLeftSeconds: 500,
      showingFeedback: false,
      startedAtMs: 1,
      pendingSelection: 2,
    );
    await store.savePaused(session);
    final loaded = store.loadPaused();
    expect(loaded, isNotNull);
    expect(loaded!.pendingSelection, 2);
    expect(loaded.questions.single.id, question.id);
    await store.clearPaused();
    expect(store.loadPaused(), isNull);
  });
}
