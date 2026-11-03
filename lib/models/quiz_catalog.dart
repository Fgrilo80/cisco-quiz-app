import 'question.dart';

String? _str(dynamic v) {
  if (v is String && v.trim().isNotEmpty) return v.trim();
  return null;
}

/// A top-level bank track (`ccst`, `cyber`, or a future one from the catalog).
class CatalogTrack {
  const CatalogTrack({
    required this.id,
    this.labelPt,
    this.labelEn,
    this.badgePt,
    this.badgeEn,
    this.descriptionPt,
    this.descriptionEn,
    this.color,
  });

  final String id;
  final String? labelPt;
  final String? labelEn;
  final String? badgePt;
  final String? badgeEn;
  final String? descriptionPt;
  final String? descriptionEn;
  final String? color;

  String? label({required bool isPt}) =>
      isPt ? (labelPt ?? labelEn) : (labelEn ?? labelPt);
  String? badge({required bool isPt}) =>
      isPt ? (badgePt ?? badgeEn) : (badgeEn ?? badgePt);
  String? description({required bool isPt}) => isPt
      ? (descriptionPt ?? descriptionEn)
      : (descriptionEn ?? descriptionPt);

  static CatalogTrack? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = _str(raw['id']);
    if (id == null) return null;
    return CatalogTrack(
      id: id,
      labelPt: _str(raw['labelPt']),
      labelEn: _str(raw['labelEn']),
      badgePt: _str(raw['badgePt']),
      badgeEn: _str(raw['badgeEn']),
      descriptionPt: _str(raw['descriptionPt']),
      descriptionEn: _str(raw['descriptionEn']),
      color: _str(raw['color']),
    );
  }
}

/// A filtered view over one track: an exam (`kind: exam`), a theme
/// (`kind: topic`) or anything else the catalog defines later.
class CatalogQuiz {
  const CatalogQuiz({
    required this.id,
    required this.kind,
    required this.parent,
    required this.filter,
    required this.labelPt,
    required this.labelEn,
    this.badgePt,
    this.badgeEn,
    this.color,
  });

  final String id;
  final String kind;
  final String parent;

  /// field → accepted values (any of). All fields must match.
  final Map<String, List<String>> filter;
  final String labelPt;
  final String labelEn;
  final String? badgePt;
  final String? badgeEn;
  final String? color;

  String label({required bool isPt}) => isPt ? labelPt : labelEn;
  String badge({required bool isPt}) =>
      (isPt ? (badgePt ?? badgeEn) : (badgeEn ?? badgePt)) ??
      kind.toUpperCase();

  bool matches(Question q) {
    for (final entry in filter.entries) {
      final value = q.field(entry.key)?.trim().toLowerCase();
      if (value == null || value.isEmpty) return false;
      if (!entry.value.contains(value)) return false;
    }
    return true;
  }

  List<Question> apply(Iterable<Question> pool) => [
    for (final q in pool)
      if (matches(q)) q,
  ];

  static CatalogQuiz? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = _str(raw['id']);
    final parent = _str(raw['parent']);
    if (id == null || parent == null) return null;
    final rawFilter = raw['filter'];
    if (rawFilter is! Map || rawFilter.isEmpty) return null;
    final filter = <String, List<String>>{};
    rawFilter.forEach((k, v) {
      final values = <String>[
        if (v is String && v.trim().isNotEmpty) v.trim().toLowerCase(),
        if (v is List)
          for (final x in v)
            if (x is String && x.trim().isNotEmpty) x.trim().toLowerCase(),
      ];
      if (values.isNotEmpty) filter['$k'] = values;
    });
    if (filter.isEmpty) return null;
    final labelPt = _str(raw['labelPt']) ?? _str(raw['labelEn']) ?? id;
    final labelEn = _str(raw['labelEn']) ?? labelPt;
    return CatalogQuiz(
      id: id,
      kind: _str(raw['kind']) ?? 'quiz',
      parent: parent,
      filter: filter,
      labelPt: labelPt,
      labelEn: labelEn,
      badgePt: _str(raw['badgePt']),
      badgeEn: _str(raw['badgeEn']),
      color: _str(raw['color']),
    );
  }
}

class QuizCatalog {
  const QuizCatalog({
    required this.version,
    required this.tracks,
    required this.quizzes,
  });

  static const empty = QuizCatalog(version: '', tracks: [], quizzes: []);

  final String version;
  final List<CatalogTrack> tracks;
  final List<CatalogQuiz> quizzes;

  bool get isEmpty => tracks.isEmpty && quizzes.isEmpty;

  CatalogTrack? track(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  CatalogQuiz? quiz(String id) {
    for (final q in quizzes) {
      if (q.id == id) return q;
    }
    return null;
  }

  List<CatalogQuiz> quizzesFor(String trackId) => [
    for (final q in quizzes)
      if (q.parent == trackId) q,
  ];

  /// Track ids in catalog order (used to order tracks the app does not know).
  List<String> get trackOrder => [for (final t in tracks) t.id];

  /// topic value → (PT, EN) label, from `kind: topic` quizzes that filter
  /// on a single topic. Lets the topic chips show «Criptografia e PKI»
  /// instead of the raw slug.
  Map<String, (String, String)> get topicLabels {
    final out = <String, (String, String)>{};
    for (final q in quizzes) {
      final values = q.filter['topic'];
      if (q.filter.length == 1 && values != null && values.length == 1) {
        out[values.first] = (q.labelPt, q.labelEn);
      }
    }
    return out;
  }

  /// Parses `data/quiz-catalog.json`. Returns null when the payload is not
  /// a catalog at all; drops malformed entries otherwise.
  static QuizCatalog? tryParse(dynamic decoded) {
    if (decoded is! Map) return null;
    final rawTracks = decoded['tracks'];
    final rawQuizzes = decoded['quizzes'];
    if (rawTracks is! List && rawQuizzes is! List) return null;
    final tracks = <CatalogTrack>[
      if (rawTracks is List)
        for (final t in rawTracks) ?CatalogTrack.fromJson(t),
    ];
    final seen = <String>{};
    final quizzes = <CatalogQuiz>[
      if (rawQuizzes is List)
        for (final q in rawQuizzes)
          if (CatalogQuiz.fromJson(q) case final quiz? when seen.add(quiz.id))
            quiz,
    ];
    return QuizCatalog(
      version: _str(decoded['version']) ?? '',
      tracks: tracks,
      quizzes: quizzes,
    );
  }
}

/// Section order for quiz kinds on the track screen.
int quizKindRank(String kind) {
  switch (kind) {
    case 'exam':
      return 0;
    case 'topic':
      return 1;
    case 'scenario':
      return 2;
    default:
      return 3;
  }
}
