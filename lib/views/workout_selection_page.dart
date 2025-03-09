import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/workout_plan.dart';
import 'workout_recording_page.dart';

class WorkoutSelectionPage extends StatefulWidget {
  const WorkoutSelectionPage({super.key});

  @override
  WorkoutSelectionPageState createState() => WorkoutSelectionPageState();
}

class WorkoutSelectionPageState extends State<WorkoutSelectionPage> {
  List<WorkoutPlan> _workoutPlans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlans();
  }

  Future<void> _loadWorkoutPlans() async {
    try {
      final plans = await DatabaseHelper().getWorkoutPlans();
      if (mounted) {
        setState(() {
          _workoutPlans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Failed to load workout plans.";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading workout plans. Please try again.')),
        );
      }
    }
  }

  void _startWorkout(WorkoutPlan plan, String type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => WorkoutRecordingPage(workoutPlan: plan, workoutType: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Workout Plan')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        )
            : _workoutPlans.isEmpty
            ? const Center(
          child: Text(
            "No workout plans found.\nDownload one first!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        )
            : ListView.builder(
          itemCount: _workoutPlans.length,
          itemBuilder: (context, index) {
            final plan = _workoutPlans[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  plan.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.fitness_center, color: Colors.blueAccent),
                onTap: () {
                  _showWorkoutTypeDialog(plan);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWorkoutTypeDialog(WorkoutPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Workout Type"),
        content: const Text("Choose how you want to perform this workout."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startWorkout(plan, "Solo");
            },
            child: const Text("Solo"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startWorkout(plan, "Collaborative");
            },
            child: const Text("Collaborative"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startWorkout(plan, "Competitive");
            },
            child: const Text("Competitive"),
          ),
        ],
      ),
    );
  }
}
