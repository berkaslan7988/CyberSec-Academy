// Command evaluation engine (pure Dart).
//
// Goal: judge a user-typed shell command flexibly but correctly.
//   - tool name required (requiredTokens)
//   - equivalent flags accepted (requiredFlagGroups + flagAliases)
//   - flag order ignored
//   - targets (IP/host/file) must be present
//   - forbidden tokens reject the answer
//   - exact accepted solutions short-circuit to "correct"
//   - partial credit when some (but not all) requirements are met
//
// This engine NEVER executes commands. It only compares text.

import '../models/answer_result.dart';
import '../models/question.dart';

class CommandEvaluator {
  /// Split a command line into tokens, honoring single/double quotes.
  /// Collapses repeated whitespace. Does not expand globs or variables.
  static List<String> tokenize(String input) {
    final tokens = <String>[];
    final buf = StringBuffer();
    String? quote; // active quote char or null
    var hasChar = false;

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (quote != null) {
        if (c == quote) {
          quote = null;
        } else {
          buf.write(c);
        }
        hasChar = true;
      } else if (c == '"' || c == "'") {
        quote = c;
        hasChar = true;
      } else if (c == ' ' || c == '\t' || c == '\n') {
        if (hasChar) {
          tokens.add(buf.toString());
          buf.clear();
          hasChar = false;
        }
      } else {
        buf.write(c);
        hasChar = true;
      }
    }
    if (hasChar) tokens.add(buf.toString());
    return tokens;
  }

  /// Normalize tokens: optionally drop a leading `sudo`, apply flag aliases,
  /// and lower-case ONLY the first token (tool name). Flags/targets stay
  /// case-sensitive because e.g. `-sV` differs from `-sv`.
  static List<String> _normalize(List<String> tokens, CommandSpec spec) {
    var t = List<String>.from(tokens);
    if (spec.allowSudo && t.isNotEmpty && t.first.toLowerCase() == 'sudo') {
      t = t.sublist(1);
    }
    if (t.isNotEmpty) {
      t[0] = t[0].toLowerCase();
    }
    // Apply aliases (e.g. --version-scan -> -sV).
    t = t.map((tok) => spec.flagAliases[tok] ?? tok).toList();
    return t;
  }

  static String _canonical(String input, CommandSpec spec) =>
      _normalize(tokenize(input), spec).join(' ');

  static AnswerResult evaluate(String userInput, Question question) {
    final spec = question.command;
    if (spec == null) {
      return AnswerResult.emptyIncorrect;
    }

    final correctAnswer =
        spec.acceptedSolutions.isNotEmpty ? spec.acceptedSolutions.first : null;

    final tokens = _normalize(tokenize(userInput), spec);
    if (tokens.isEmpty) {
      return AnswerResult(
        status: AnswerStatus.incorrect,
        score: 0.0,
        missing: const ['empty'],
        correctAnswer: correctAnswer,
      );
    }
    final tokenSet = tokens.toSet();

    // Short-circuit: exact match against an accepted solution.
    final canonicalUser = tokens.join(' ');
    for (final sol in spec.acceptedSolutions) {
      if (_canonical(sol, spec) == canonicalUser) {
        return AnswerResult(
          status: AnswerStatus.correct,
          score: 1.0,
          correctAnswer: correctAnswer,
        );
      }
    }

    // Forbidden tokens => immediate incorrect.
    for (final f in spec.forbiddenTokens) {
      if (tokenSet.contains(f)) {
        return AnswerResult(
          status: AnswerStatus.incorrect,
          score: 0.0,
          missing: ['forbidden:$f'],
          correctAnswer: correctAnswer,
        );
      }
    }

    final missing = <String>[];
    var satisfied = 0;
    var total = 0;
    var requiredTokenMissing = false;

    // 1) Required tokens (tool name etc.). Tool name compared case-insensitively.
    // These are a hard gate: if the tool name is wrong/absent the whole answer
    // is incorrect, even if a target or flag happened to match.
    for (final req in spec.requiredTokens) {
      total++;
      final reqNorm = req.toLowerCase();
      final present =
          tokenSet.contains(req) || tokens.any((t) => t.toLowerCase() == reqNorm);
      if (present) {
        satisfied++;
      } else {
        missing.add('token:$req');
        requiredTokenMissing = true;
      }
    }

    // 2) Required flag groups (any-of within each group).
    for (final group in spec.requiredFlagGroups) {
      total++;
      final hit = group.anyOf.any((flag) {
        final canonical = spec.flagAliases[flag] ?? flag;
        return tokenSet.contains(flag) || tokenSet.contains(canonical);
      });
      if (hit) {
        satisfied++;
      } else {
        missing.add('flag:${group.anyOf.join("|")}');
      }
    }

    // 3) Required targets.
    for (final target in spec.requiredTargets) {
      total++;
      if (tokenSet.contains(target)) {
        satisfied++;
      } else {
        missing.add('target:$target');
      }
    }

    if (total == 0) {
      // No constraints defined: accept any non-empty input.
      return AnswerResult(
          status: AnswerStatus.correct, score: 1.0, correctAnswer: correctAnswer);
    }

    final score = satisfied / total;
    final AnswerStatus status;
    if (satisfied == total) {
      status = AnswerStatus.correct;
    } else if (satisfied == 0 || requiredTokenMissing) {
      // Wrong/missing tool name => incorrect, regardless of partial matches.
      status = AnswerStatus.incorrect;
    } else {
      status = AnswerStatus.partiallyCorrect;
    }

    return AnswerResult(
      status: status,
      score: score,
      missing: missing,
      correctAnswer: correctAnswer,
    );
  }
}
