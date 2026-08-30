import 'question.dart';

const int quizLength = 50;
const int quizSeconds = 45 * 60;

class QuizSession {
  QuizSession({
    required this.cert,
    required this.examLang,
    required this.questions,
    required this.answers,
    required this.currentIndex,
    required this.timeLeftSeconds,
    required this.showingFeedback,
    required this.startedAtMs,
  });

  final String cert;
  final String examLang;
  final List<Question> questions;
  final List<int?> answers;
  int currentIndex;
  int timeLeftSeconds;
  bool showingFeedback;
  final int startedAtMs;

  int get length => questions.length;

  Question get current => questions[currentIndex];

  bool get isLast => currentIndex >= length - 1;

  int get answeredCount => answers.where((a) => a != null).length;

  int get correctCount {
    var n = 0;
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].isCorrect(answers[i])) n++;
    }
    return n;
  }

  int get usedSeconds => (quizSeconds - timeLeftSeconds).clamp(0, quizSeconds);

  Map<String, dynamic> toJson() => {
        'cert': cert,
        'examLang': examLang,
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': answers,
        'currentIndex': currentIndex,
        'timeLeftSeconds': timeLeftSeconds,
        'showingFeedback': showingFeedback,
        'startedAtMs': startedAtMs,
      };

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    final rawQs = json['questions'];
    final questions = rawQs is List
        ? rawQs
            .whereType<Map>()
            .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <Question>[];
    final rawAnswers = json['answers'];
    final answers = <int?>[
      for (final a in (rawAnswers is List ? rawAnswers : const []))
        a == null ? null : int.tryParse('$a'),
    ];
    while (answers.length < questions.length) {
      answers.add(null);
    }
    return QuizSession(
      cert: '${json['cert'] ?? ''}',
      examLang: '${json['examLang'] ?? 'pt'}',
      questions: questions,
      answers: answers.take(questions.length).toList(),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      timeLeftSeconds: (json['timeLeftSeconds'] as num?)?.toInt() ?? quizSeconds,
      showingFeedback: json['showingFeedback'] == true,
      startedAtMs: (json['startedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}
