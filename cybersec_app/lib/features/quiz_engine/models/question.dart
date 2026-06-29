// Quiz engine — data models
//
// Pure Dart (no Flutter dependency) so the logic stays testable and portable.
// Each Question is JSON-driven so content can live in assets/quizzes/*.json.

/// Supported question types.
enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank,
  command,
  matching,
  ordering;

  static QuestionType fromString(String s) {
    switch (s) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_blank':
        return QuestionType.fillBlank;
      case 'command':
        return QuestionType.command;
      case 'matching':
        return QuestionType.matching;
      case 'ordering':
        return QuestionType.ordering;
      default:
        throw ArgumentError('Unknown question type: $s');
    }
  }
}

enum Difficulty { easy, medium, hard }

Difficulty _difficultyFromString(String? s) {
  switch (s) {
    case 'hard':
      return Difficulty.hard;
    case 'medium':
      return Difficulty.medium;
    default:
      return Difficulty.easy;
  }
}

/// A localized string holding both Turkish and English variants.
class LocalizedText {
  final String tr;
  final String en;

  const LocalizedText({required this.tr, required this.en});

  /// `lang` is 'tr' or 'en'. Falls back to the other language if empty.
  String resolve(String lang) {
    final value = lang == 'tr' ? tr : en;
    if (value.isNotEmpty) return value;
    return lang == 'tr' ? en : tr;
  }

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      LocalizedText(tr: (json['tr'] ?? '') as String, en: (json['en'] ?? '') as String);

  factory LocalizedText.fromAny(dynamic v) {
    if (v is Map<String, dynamic>) return LocalizedText.fromJson(v);
    final s = (v ?? '').toString();
    return LocalizedText(tr: s, en: s);
  }
}

/// A single selectable option (multiple choice / true-false).
class AnswerOption {
  final LocalizedText label;
  final bool correct;

  const AnswerOption({required this.label, this.correct = false});

  factory AnswerOption.fromJson(Map<String, dynamic> json) => AnswerOption(
        label: LocalizedText.fromJson(json),
        correct: (json['correct'] ?? false) as bool,
      );
}

/// One equivalent-flag group. The command must contain at least one of these.
/// e.g. ['-sV', '--version-scan'] means "-sV OR --version-scan".
class FlagGroup {
  final List<String> anyOf;
  const FlagGroup(this.anyOf);

  factory FlagGroup.fromJson(dynamic v) =>
      FlagGroup((v as List).map((e) => e.toString()).toList());
}

/// Evaluation spec for `command` questions.
class CommandSpec {
  /// Tokens that must be present (typically the tool name), e.g. ['nmap'].
  final List<String> requiredTokens;

  /// Each group: at least one of its flags must appear.
  final List<FlagGroup> requiredFlagGroups;

  /// Targets that must appear verbatim as a token (IP/host/file).
  final List<String> requiredTargets;

  /// Tokens that must NOT appear (wrong/dangerous answers).
  final List<String> forbiddenTokens;

  /// alias -> canonical (e.g. '--version-scan' -> '-sV'). Normalized before checks.
  final Map<String, String> flagAliases;

  /// Strip a leading `sudo` before evaluation.
  final bool allowSudo;

  /// If the normalized command equals one of these, it is instantly correct.
  final List<String> acceptedSolutions;

  const CommandSpec({
    this.requiredTokens = const [],
    this.requiredFlagGroups = const [],
    this.requiredTargets = const [],
    this.forbiddenTokens = const [],
    this.flagAliases = const {},
    this.allowSudo = true,
    this.acceptedSolutions = const [],
  });

  factory CommandSpec.fromJson(Map<String, dynamic> json) => CommandSpec(
        requiredTokens:
            ((json['requiredTokens'] ?? []) as List).map((e) => e.toString()).toList(),
        requiredFlagGroups: ((json['requiredFlagGroups'] ?? []) as List)
            .map((e) => FlagGroup.fromJson(e))
            .toList(),
        requiredTargets:
            ((json['requiredTargets'] ?? []) as List).map((e) => e.toString()).toList(),
        forbiddenTokens:
            ((json['forbiddenTokens'] ?? []) as List).map((e) => e.toString()).toList(),
        flagAliases: ((json['flagAliases'] ?? <String, dynamic>{}) as Map)
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        allowSudo: (json['allowSudo'] ?? true) as bool,
        acceptedSolutions:
            ((json['acceptedSolutions'] ?? []) as List).map((e) => e.toString()).toList(),
      );
}

/// The unified question model. Fields not relevant to a type stay empty/null.
class Question {
  final String id;
  final QuestionType type;
  final Difficulty difficulty;
  final LocalizedText prompt;
  final LocalizedText explanation;

  // multiple_choice / true_false
  final List<AnswerOption> options;

  // fill_blank: list of accepted answers (case-insensitive)
  final List<String> acceptedAnswers;

  // command
  final CommandSpec? command;

  // matching: left -> correct right (both localized labels by key)
  final List<MatchPair> pairs;

  // ordering: items in the CORRECT order
  final List<LocalizedText> orderedItems;

  const Question({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.prompt,
    required this.explanation,
    this.options = const [],
    this.acceptedAnswers = const [],
    this.command,
    this.pairs = const [],
    this.orderedItems = const [],
  });

  /// Returns a copy of this question with a different [id]. Used by the review
  /// session to tag questions with their composite "sectionId/questionId" key.
  Question withId(String newId) => Question(
        id: newId,
        type: type,
        difficulty: difficulty,
        prompt: prompt,
        explanation: explanation,
        options: options,
        acceptedAnswers: acceptedAnswers,
        command: command,
        pairs: pairs,
        orderedItems: orderedItems,
      );

  factory Question.fromJson(Map<String, dynamic> json) {
    final type = QuestionType.fromString(json['type'] as String);
    return Question(
      id: json['id'] as String,
      type: type,
      difficulty: _difficultyFromString(json['difficulty'] as String?),
      prompt: LocalizedText.fromAny(json['prompt']),
      explanation: LocalizedText.fromAny(json['explanation']),
      options: ((json['options'] ?? []) as List)
          .map((e) => AnswerOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptedAnswers:
          ((json['acceptedAnswers'] ?? []) as List).map((e) => e.toString()).toList(),
      command: json['evaluation'] != null
          ? CommandSpec.fromJson(json['evaluation'] as Map<String, dynamic>)
          : null,
      pairs: ((json['pairs'] ?? []) as List)
          .map((e) => MatchPair.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderedItems: ((json['orderedItems'] ?? []) as List)
          .map((e) => LocalizedText.fromAny(e))
          .toList(),
    );
  }
}

class MatchPair {
  final LocalizedText left;
  final LocalizedText right;
  const MatchPair({required this.left, required this.right});

  factory MatchPair.fromJson(Map<String, dynamic> json) => MatchPair(
        left: LocalizedText.fromAny(json['left']),
        right: LocalizedText.fromAny(json['right']),
      );
}
