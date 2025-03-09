import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../views/workout_recording_page.dart';
import '../views/workout_details.dart';
import '../views/download_workout_page.dart';
import '../views/workout_selection_page.dart';
import '../widgets/recent_performance_widget.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  WorkoutHistoryPageState createState() => WorkoutHistoryPageState();
}

class WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<Workout> _workoutHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
  }

  Future<void> _loadWorkoutHistory() async {
    try {
      final dbHelper = DatabaseHelper();
      final workouts = await dbHelper.getWorkoutHistory();

      if (!mounted) return;

      setState(() {
        _workoutHistory = workouts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = "Failed to load workout history.";
        _isLoading = false;
      });
    }
  }

  void _navigateToWorkoutDetails(Workout workout) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => WorkoutDetailsPage(workout: workout)),
    );
  }

  void _navigateToDownloadPage() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DownloadWorkoutPage()),
    );
  }

  Future<void> _startNewWorkout() async {
    if (!mounted) return;
    final selectedPlan = await Navigator.of(context).push<WorkoutPlan>(
      MaterialPageRoute(builder: (context) => const WorkoutSelectionPage()),
    );

    if (!mounted || selectedPlan == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutRecordingPage(
          workoutPlan: selectedPlan,
          workoutType: "Solo",
        ),
      ),
    );

    if (mounted) {
      _loadWorkoutHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: Column(
        children: [
          const RecentPerformanceWidget(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _workoutHistory.isEmpty
                ? const Center(
              child: Text(
                "No workouts recorded yet. Start a new workout!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
                : ListView.builder(
              itemCount: _workoutHistory.length,
              itemBuilder: (context, index) {
                final workout = _workoutHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      workout.date.toLocal().toString().split(' ')[0],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${workout.results.length} exercises completed"),
                    onTap: () => _navigateToWorkoutDetails(workout),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'downloadWorkout',
            backgroundColor: Colors.orange,
            onPressed: _navigateToDownloadPage,
            child: const Icon(Icons.cloud_download),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'startWorkout',
            backgroundColor: Colors.blue,
            onPressed: _startNewWorkout,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
