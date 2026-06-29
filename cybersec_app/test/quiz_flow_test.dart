// Widget test for the quiz UI flow: select an option, check, see feedback.
// Run with: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cybersec_app/features/quiz_engine/models/question.dart';
import 'package:cybersec_app/features/quiz_engine/models/quiz.dart';
import 'package:cybersec_app/features/quiz_engine/state/quiz_controller.dart';
import 'package:cybersec_app/features/quiz_engine/ui/quiz_screen.dart';

Quiz _singleMcQuiz() => Quiz(
      id: 't',
      title: const LocalizedText(tr: 'Test', en: 'Test'),
      questions: [
        const Question(
          id: 'q1',
          type: QuestionType.multipleChoice,
          difficulty: Difficulty.easy,
          prompt: LocalizedText(tr: 'Soru metni', en: 'Question'),
          explanation: LocalizedText(tr: 'Açıklama metni', en: 'Explanation'),
          options: [
            AnswerOption(
                label: LocalizedText(tr: 'Doğru şık', en: 'Right'),
                correct: true),
            AnswerOption(label: LocalizedText(tr: 'Yanlış şık', en: 'Wrong')),
          ],
        ),
      ],
    );

void main() {
  testWidgets('correct answer shows positive feedback', (tester) async {
    final controller = QuizController(_singleMcQuiz());
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: QuizScreen(
        controller: controller,
        lang: 'tr',
        onToggleLang: () {},
      ),
    ));

    // Prompt visible.
    expect(find.text('Soru metni'), findsOneWidget);

    // Select the correct option, then check.
    await tester.tap(find.text('Doğru şık'));
    await tester.pump();
    await tester.tap(find.text('Kontrol Et'));
    await tester.pumpAndSettle();

    // Feedback + explanation appear.
    expect(find.text('Doğru!'), findsOneWidget);
    expect(find.text('Açıklama metni'), findsOneWidget);
  });

  testWidgets('wrong answer reveals the explanation', (tester) async {
    final controller = QuizController(_singleMcQuiz());
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: QuizScreen(
        controller: controller,
        lang: 'tr',
        onToggleLang: () {},
      ),
    ));

    await tester.tap(find.text('Yanlış şık'));
    await tester.pump();
    await tester.tap(find.text('Kontrol Et'));
    await tester.pumpAndSettle();

    expect(find.text('Yanlış.'), findsOneWidget);
    expect(find.text('Açıklama metni'), findsOneWidget);
  });
}
