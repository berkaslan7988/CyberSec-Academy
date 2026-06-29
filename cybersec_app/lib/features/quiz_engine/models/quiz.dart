import 'question.dart';

/// A quiz = ordered set of questions with a localized title.
class Quiz {
  final String id;
  final LocalizedText title;
  final List<Question> questions;

  const Quiz({required this.id, required this.title, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'] as String,
        title: LocalizedText.fromAny(json['title']),
        questions: ((json['questions'] ?? []) as List)
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
