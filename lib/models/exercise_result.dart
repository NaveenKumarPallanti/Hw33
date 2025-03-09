import 'exercise.dart';

class ExerciseResult {
  final Exercise exercise;
  final int achievedOutput;
  final int? timeElapsed;

  ExerciseResult({required this.exercise, required this.achievedOutput, this.timeElapsed});

  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise.toMap(),
      'achievedOutput': achievedOutput,
      'timeElapsed': timeElapsed ?? 0,
    };
  }

  factory ExerciseResult.fromMap(Map<String, dynamic> map) {
    return ExerciseResult(
      exercise: Exercise.fromMap(map['exercise'] as Map<String, dynamic>),
      achievedOutput: map['achievedOutput'] as int,
      timeElapsed: map.containsKey('timeElapsed') ? map['timeElapsed'] as int? : null,
    );
  }
}
