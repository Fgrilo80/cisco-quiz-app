/// A single multiple-choice item from the bundled bank.
class Question {
  const Question({
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
    required this.difficulty,
    this.cli,
  });

  final String question;
  final List<String> options;
  final int correct;
  final String explanation;
  final String difficulty;

  /// Optional CLI / show-command output to render in a monospace block.
  final String? cli;

  /// Stable id used to remember seen questions (normalized prompt).
  String get id {
    final normalized = question.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length <= 200 ? normalized : normalized.substring(0, 200);
  }

  bool get hasCli => cli != null && cli!.trim().isNotEmpty;

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
    final correct = rawCorrect is int
        ? rawCorrect
        : int.tryParse('$rawCorrect') ?? 0;
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
    return Question(
      question: '${json['question'] ?? ''}',
      options: options,
      correct: correct.clamp(0, options.isEmpty ? 0 : options.length - 1),
      explanation: '${json['explanation'] ?? ''}',
      difficulty: '${json['difficulty'] ?? ''}',
      cli: cli,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct': correct,
        'explanation': explanation,
        'difficulty': difficulty,
        if (hasCli) 'cli': cli,
      };
}
