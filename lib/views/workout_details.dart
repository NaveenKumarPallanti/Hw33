import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';

class WorkoutDetailsPage extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailsPage({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Workout Date: ${_formatDate(workout.date)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (workout.results.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No exercises recorded for this workout.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: workout.results.length,
                  itemBuilder: (context, index) {
                    final result = workout.results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.fitness_center, color: Colors.blueAccent),
                        title: Text(
                          result.exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Target: ${result.exercise.targetOutput} ${result.exercise.unit}\n"
                              "Achieved: ${result.achievedOutput} ${result.exercise.unit}",
                        ),
                        trailing: Icon(
                          result.achievedOutput >= result.exercise.targetOutput
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: result.achievedOutput >= result.exercise.targetOutput
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
