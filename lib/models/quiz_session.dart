import 'question.dart';

const int quizLength = 50;
const int quizSeconds = 45 * 60;

enum QuizMode {
  practice,
  exam,
  review;

  bool get isExam => this == QuizMode.exam;

  bool get isPractice => this == QuizMode.practice;

  bool get isReview => this == QuizMode.review;

  static QuizMode parse(dynamic value) {
    switch ('$value'.toLowerCase()) {
      case 'exam':
        return QuizMode.exam;
      case 'review':
        return QuizMode.review;
      default:
        return QuizMode.practice;
    }
  }
}

int _asInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

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
    this.pendingSelection,
    this.mode = QuizMode.practice,
    int? durationSeconds,
  }) : durationSeconds = durationSeconds ?? quizSeconds;

  final String cert;
  final String examLang;
  final List<Question> questions;
  final List<int?> answers;
  int currentIndex;
  int timeLeftSeconds;
  bool showingFeedback;
  final int startedAtMs;
  final QuizMode mode;
  final int durationSeconds;

  /// Unconfirmed option on the current question (pause / process-death).
  int? pendingSelection;

  int get length => questions.length;

  Question get current => questions[currentIndex];

  bool get isLast => currentIndex >= length - 1;

  bool get isExam => mode.isExam;

  bool get isPractice => mode.isPractice;

  bool get isReview => mode.isReview;

  /// Practice and review reveal after each answer; exam waits until results.
  bool get revealsAfterAnswer => !isExam;

  int get answeredCount => answers.where((a) => a != null).length;

  int get correctCount {
    var n = 0;
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].isCorrect(answers[i])) n++;
    }
    return n;
  }

  List<Question> get missedQuestions {
    final missed = <Question>[];
    for (var i = 0; i < questions.length; i++) {
      if (!questions[i].isCorrect(answers[i])) missed.add(questions[i]);
    }
    return missed;
  }

  List<Question> get hitQuestions {
    final hits = <Question>[];
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].isCorrect(answers[i])) hits.add(questions[i]);
    }
    return hits;
  }

  int get scorePercent {
    if (questions.isEmpty) return 0;
    return ((correctCount / questions.length) * 100).round();
  }

  int get usedSeconds =>
      (durationSeconds - timeLeftSeconds).clamp(0, durationSeconds);

  Map<String, dynamic> toJson() => {
    'cert': cert,
    'examLang': examLang,
    'questions': questions.map((q) => q.toJson()).toList(),
    'answers': answers,
    'currentIndex': currentIndex,
    'timeLeftSeconds': timeLeftSeconds,
    'showingFeedback': showingFeedback,
    'startedAtMs': startedAtMs,
    'pendingSelection': pendingSelection,
    'mode': mode.name,
    'durationSeconds': durationSeconds,
  };

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    final rawQs = json['questions'];
    final questions = rawQs is List
        ? rawQs
              .whereType<Map>()
              .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
              .where((q) => q.isValid)
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
    final trimmed = answers.take(questions.length).toList();
    for (var i = 0; i < trimmed.length; i++) {
      final a = trimmed[i];
      final n = questions[i].options.length;
      if (a != null && (a < 0 || a >= n)) trimmed[i] = null;
    }
    final last = questions.isEmpty ? 0 : questions.length - 1;
    var idx = _asInt(json['currentIndex'], 0).clamp(0, last);
    final duration = _asInt(
      json['durationSeconds'],
      quizSeconds,
    ).clamp(60, quizSeconds);
    var timeLeft = _asInt(json['timeLeftSeconds'], duration).clamp(0, duration);
    var pending = json['pendingSelection'] == null
        ? null
        : int.tryParse('${json['pendingSelection']}');
    if (pending != null && questions.isNotEmpty) {
      final n = questions[idx].options.length;
      if (pending < 0 || pending >= n) pending = null;
    }
    return QuizSession(
      cert: '${json['cert'] ?? ''}',
      examLang: '${json['examLang'] ?? 'pt'}',
      questions: questions,
      answers: trimmed,
      currentIndex: idx,
      timeLeftSeconds: timeLeft,
      showingFeedback: json['showingFeedback'] == true,
      startedAtMs: _asInt(json['startedAtMs'], 0),
      pendingSelection: pending,
      mode: QuizMode.parse(json['mode']),
      durationSeconds: duration,
    );
  }
}
