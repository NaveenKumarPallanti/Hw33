import 'exercise.dart';

class WorkoutPlan {
  int? id;
  final String name;
  final List<Exercise> exercises;

  WorkoutPlan({this.id, required this.name, required this.exercises});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map, List<Exercise> exercises) {
    return WorkoutPlan(
      id: map.containsKey('id') ? map['id'] as int? : null,
      name: map['name'] as String,
      exercises: exercises,
    );
  }
}
