import 'exercise_result.dart';

class Workout {
  final DateTime date;
  final List<ExerciseResult> results;

  Workout({required this.date, required this.results});

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'results': results.map((r) => r.toMap()).toList(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      date: DateTime.parse(map['date']),
      results: (map['results'] as List).map((r) => ExerciseResult.fromMap(r)).toList(),
    );
  }
}
