import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';

class DatabaseHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? "default_user";

  Future<void> insertWorkoutPlan(WorkoutPlan plan) async {
    await _firestore.collection('users/$userId/workout_plans').add({
      'name': plan.name,
      'exercises': plan.exercises.map((e) => e.toMap()).toList(),
    });
  }

  Future<List<WorkoutPlan>> getWorkoutPlans() async {
    final snapshot = await _firestore.collection('users/$userId/workout_plans').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final exercises = (data['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList();

      return WorkoutPlan.fromMap(data, exercises); // ✅ FIXED: Passing exercises correctly
    }).toList();
  }

  Future<void> insertWorkout(Workout workout) async {
    await _firestore.collection('users/$userId/workouts').add({
      'date': workout.date.toIso8601String(),
      'results': workout.results.map((res) => {
        'exercise': res.exercise.toMap(),
        'achievedOutput': res.achievedOutput,
        'timeElapsed': res.timeElapsed ?? 0,
      }).toList(),
    });
  }

  Future<List<Workout>> getWorkoutHistory() async {
    final snapshot = await _firestore
        .collection('users/$userId/workouts')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final results = (data['results'] as List<dynamic>).map((res) {
        final exerciseData = res['exercise'] as Map<String, dynamic>;
        return ExerciseResult(
          exercise: Exercise.fromMap(exerciseData),
          achievedOutput: res['achievedOutput'] as int,
          timeElapsed: res['timeElapsed'] as int?,
        );
      }).toList();

      return Workout(
        date: DateTime.parse(data['date']),
        results: results,
      );
    }).toList();
  }
}
