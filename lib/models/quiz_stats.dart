class QuizStats {
  const QuizStats({
    this.sessions = 0,
    this.examSessions = 0,
    this.practiceSessions = 0,
    this.reviewSessions = 0,
    this.answered = 0,
    this.correct = 0,
    this.lastCorrect = 0,
    this.lastTotal = 0,
    this.lastCert = '',
    this.lastFiveExamPct = const [],
    this.lastPctByCert = const {},
  });

  final int sessions;
  final int examSessions;
  final int practiceSessions;
  final int reviewSessions;
  final int answered;
  final int correct;
  final int lastCorrect;
  final int lastTotal;
  final String lastCert;
  final List<int> lastFiveExamPct;
  final Map<String, int> lastPctByCert;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  int get lastPct =>
      lastTotal == 0 ? 0 : ((lastCorrect / lastTotal) * 100).round();

  int? get lastFiveAvg {
    if (lastFiveExamPct.isEmpty) return null;
    var sum = 0;
    for (final n in lastFiveExamPct) {
      sum += n;
    }
    return (sum / lastFiveExamPct.length).round();
  }

  bool get isEmpty => sessions == 0 && answered == 0 && lastPctByCert.isEmpty;

  Map<String, dynamic> toJson() => {
    'sessions': sessions,
    'examSessions': examSessions,
    'practiceSessions': practiceSessions,
    'reviewSessions': reviewSessions,
    'answered': answered,
    'correct': correct,
    'lastCorrect': lastCorrect,
    'lastTotal': lastTotal,
    'lastCert': lastCert,
    'lastFiveExamPct': lastFiveExamPct,
    'lastPctByCert': lastPctByCert,
  };

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final rawFive = json['lastFiveExamPct'] ?? json['lastFive'];
    final five = <int>[
      for (final n in (rawFive is List ? rawFive : const []))
        if (n is num)
          n.round()
        else if (int.tryParse('$n') != null)
          int.parse('$n'),
    ];
    final rawMap = json['lastPctByCert'];
    final byCert = <String, int>{};
    if (rawMap is Map) {
      rawMap.forEach((key, value) {
        if (value is num) {
          byCert['$key'] = value.round();
        } else {
          final parsed = int.tryParse('$value');
          if (parsed != null) byCert['$key'] = parsed;
        }
      });
    }

    return QuizStats(
      sessions: asInt(json['sessions']),
      examSessions: asInt(json['examSessions']),
      practiceSessions: asInt(json['practiceSessions']),
      reviewSessions: asInt(json['reviewSessions']),
      answered: asInt(json['answered']),
      correct: asInt(json['correct']),
      lastCorrect: asInt(json['lastCorrect']),
      lastTotal: asInt(json['lastTotal']),
      lastCert: '${json['lastCert'] ?? ''}',
      lastFiveExamPct: five.length <= 5 ? five : five.sublist(five.length - 5),
      lastPctByCert: byCert,
    );
  }

  QuizStats record({
    required String cert,
    required String mode,
    required int hits,
    required int total,
  }) {
    final pct = total == 0 ? 0 : ((hits / total) * 100).round();
    final nextByCert = Map<String, int>.from(lastPctByCert);
    if (cert.isNotEmpty) nextByCert[cert] = pct;
    var five = lastFiveExamPct;
    if (mode == 'exam') {
      five = [...lastFiveExamPct, pct];
      if (five.length > 5) five = five.sublist(five.length - 5);
    }
    return QuizStats(
      sessions: sessions + 1,
      examSessions: examSessions + (mode == 'exam' ? 1 : 0),
      practiceSessions: practiceSessions + (mode == 'practice' ? 1 : 0),
      reviewSessions: reviewSessions + (mode == 'review' ? 1 : 0),
      answered: answered + total,
      correct: correct + hits,
      lastCorrect: hits,
      lastTotal: total,
      lastCert: cert,
      lastFiveExamPct: five,
      lastPctByCert: nextByCert,
    );
  }
}
