/// A single multiple-choice item from the bundled bank.
class Question {
  const Question({
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
    required this.difficulty,
    this.cli,
    this.topic,
    this.exam,
    this.domain,
    this.tags = const {},
  });

  final String question;
  final List<String> options;
  final int correct;
  final String explanation;
  final String difficulty;

  /// Optional CLI / show-command output to render in a monospace block.
  final String? cli;

  /// Optional topic from JSON. When missing, the app derives one from keywords.
  final String? topic;

  /// Optional exam id from the catalog-aware bank (e.g. `ccst-cyber`, `scor`).
  final String? exam;

  /// Optional blueprint domain (e.g. `6.5`).
  final String? domain;

  /// Any other scalar string field from JSON, so catalog filters on new keys
  /// (e.g. `track`, `level`, `scenario`) work without code changes.
  final Map<String, String> tags;

  /// Field lookup used by catalog quiz filters.
  String? field(String key) {
    switch (key) {
      case 'exam':
        return exam;
      case 'topic':
        return topic;
      case 'domain':
        return domain;
      case 'difficulty':
        return difficulty;
      default:
        return tags[key];
    }
  }

  /// Stable id used to remember seen questions (normalized prompt).
  String get id {
    final normalized = question.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length <= 200 ? normalized : normalized.substring(0, 200);
  }

  bool get hasCli => cli != null && cli!.trim().isNotEmpty;

  /// Usable in an exam: prompt, 2+ options, in-range correct index.
  bool get isValid {
    if (question.trim().isEmpty) return false;
    if (options.length < 2) return false;
    if (options.any((o) => o.trim().isEmpty)) return false;
    if (correct < 0 || correct >= options.length) return false;
    return true;
  }

  bool isCorrect(int? answerIndex) =>
      answerIndex != null && answerIndex == correct;

  String get correctText {
    if (correct < 0 || correct >= options.length) return '';
    return options[correct];
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions.map((e) => '$e').toList()
        : <String>[];
    final rawCorrect = json['correct'];
    final int correct;
    if (rawCorrect is num) {
      correct = rawCorrect.toInt();
    } else {
      correct = int.tryParse('$rawCorrect') ?? -1;
    }
    String? cli;
    const keys = <String>[
      'cli',
      'output',
      'show',
      'show_output',
      'cli_output',
      'showOutput',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        cli = value;
        break;
      }
    }
    String? topic;
    final rawTopic = json['topic'] ?? json['topics'] ?? json['category'];
    if (rawTopic is String && rawTopic.trim().isNotEmpty) {
      topic = rawTopic.trim();
    }
    String? str(String key) {
      final v = json[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is num) return '$v';
      return null;
    }

    final tags = <String, String>{};
    final rawTags = json['tags'];
    if (rawTags is Map) {
      rawTags.forEach((k, v) {
        if (v is String && v.trim().isNotEmpty) tags['$k'] = v.trim();
      });
    }
    json.forEach((k, v) {
      if (_coreKeys.contains(k)) return;
      if (v is String && v.trim().isNotEmpty) tags[k] = v.trim();
    });
    return Question(
      question: '${json['question'] ?? ''}',
      options: options,
      correct: correct,
      explanation: '${json['explanation'] ?? ''}',
      difficulty: '${json['difficulty'] ?? ''}',
      cli: cli,
      topic: topic,
      exam: str('exam'),
      domain: str('domain'),
      tags: tags,
    );
  }

  static const _coreKeys = <String>{
    'question',
    'options',
    'correct',
    'explanation',
    'difficulty',
    'cli',
    'output',
    'show',
    'show_output',
    'cli_output',
    'showOutput',
    'topic',
    'topics',
    'category',
    'exam',
    'domain',
    'tags',
  };

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correct': correct,
    'explanation': explanation,
    'difficulty': difficulty,
    if (hasCli) 'cli': cli,
    if (topic != null && topic!.trim().isNotEmpty) 'topic': topic,
    if (exam != null && exam!.trim().isNotEmpty) 'exam': exam,
    if (domain != null && domain!.trim().isNotEmpty) 'domain': domain,
    if (tags.isNotEmpty) 'tags': tags,
  };
}
