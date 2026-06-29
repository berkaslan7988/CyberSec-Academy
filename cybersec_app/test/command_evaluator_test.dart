// Unit tests for the command evaluator. Run with: flutter test
// (Logic already validated independently via the Python reference harness.)

import 'package:flutter_test/flutter_test.dart';
import 'package:cybersec_app/features/quiz_engine/logic/command_evaluator.dart';
import 'package:cybersec_app/features/quiz_engine/models/answer_result.dart';
import 'package:cybersec_app/features/quiz_engine/models/question.dart';

Question _nmapQuestion() => Question(
      id: 'q_nmap',
      type: QuestionType.command,
      difficulty: Difficulty.medium,
      prompt: const LocalizedText(tr: '', en: ''),
      explanation: const LocalizedText(tr: '', en: ''),
      command: const CommandSpec(
        requiredTokens: ['nmap'],
        requiredFlagGroups: [
          FlagGroup(['-sV', '--version-scan'])
        ],
        requiredTargets: ['10.10.10.5'],
        flagAliases: {'--version-scan': '-sV'},
        acceptedSolutions: ['nmap -sV 10.10.10.5'],
      ),
    );

void main() {
  final q = _nmapQuestion();

  AnswerStatus eval(String input) =>
      CommandEvaluator.evaluate(input, q).status;

  group('CommandEvaluator', () {
    test('exact match is correct', () {
      expect(eval('nmap -sV 10.10.10.5'), AnswerStatus.correct);
    });
    test('tool name is case-insensitive', () {
      expect(eval('NMAP -sV 10.10.10.5'), AnswerStatus.correct);
    });
    test('flag order is ignored', () {
      expect(eval('nmap 10.10.10.5 -sV'), AnswerStatus.correct);
    });
    test('leading sudo is stripped', () {
      expect(eval('sudo nmap -sV 10.10.10.5'), AnswerStatus.correct);
    });
    test('alias --version-scan is accepted', () {
      expect(eval('nmap --version-scan 10.10.10.5'), AnswerStatus.correct);
    });
    test('extra whitespace tolerated', () {
      expect(eval('nmap   -sV    10.10.10.5'), AnswerStatus.correct);
    });
    test('missing target is partial', () {
      expect(eval('nmap -sV'), AnswerStatus.partiallyCorrect);
    });
    test('missing flag is partial', () {
      expect(eval('nmap 10.10.10.5'), AnswerStatus.partiallyCorrect);
    });
    test('wrong tool is incorrect (gated)', () {
      expect(eval('nikto -h 10.10.10.5'), AnswerStatus.incorrect);
    });
    test('missing tool is incorrect (gated)', () {
      expect(eval('-sV 10.10.10.5'), AnswerStatus.incorrect);
    });
    test('case-sensitive flag -sv != -sV is partial', () {
      expect(eval('nmap -sv 10.10.10.5'), AnswerStatus.partiallyCorrect);
    });
    test('empty input is incorrect', () {
      expect(eval(''), AnswerStatus.incorrect);
    });
  });

  group('tokenizer', () {
    test('handles quotes', () {
      expect(CommandEvaluator.tokenize("grep -r 'admin pass' /etc"),
          ['grep', '-r', 'admin pass', '/etc']);
    });
  });
}
