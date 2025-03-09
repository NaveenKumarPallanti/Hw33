import 'package:flutter/material.dart';
import '../database_helper.dart';

class RecentPerformanceWidget extends StatefulWidget {
  const RecentPerformanceWidget({super.key});

  @override
  RecentPerformanceWidgetState createState() => RecentPerformanceWidgetState();
}

class RecentPerformanceWidgetState extends State<RecentPerformanceWidget> {
  int _recentExerciseCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentWorkouts();
  }

  Future<void> _loadRecentWorkouts() async {
    try {
      final dbHelper = DatabaseHelper();
      final workouts = await dbHelper.getWorkoutHistory();

      // 🛠️ Filter workouts from last 7 days
      final recentWorkouts = workouts.where(
            (w) => w.date.isAfter(DateTime.now().subtract(const Duration(days: 7))),
      ).toList();

      // 🔢 Count total exercises in those workouts
      final score = recentWorkouts.fold(0, (sum, w) => sum + w.results.length);

      if (mounted) {
        setState(() {
          _recentExerciseCount = score;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load recent performance.";
          _isLoading = false;
        });

        // 🔔 Display error message as a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Error loading recent workouts. Please try again.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Recent Performance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : _error != null
                ? Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            )
                : Text(
              _recentExerciseCount > 0
                  ? 'Exercises in last 7 days: $_recentExerciseCount'
                  : 'No recent workouts recorded',
              style: const TextStyle(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
