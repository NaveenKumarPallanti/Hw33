import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database_helper.dart';
import 'package:hw33/models/workout_plan.dart';
import 'package:hw33/models/exercise.dart';

class DownloadWorkoutPage extends StatefulWidget {
  const DownloadWorkoutPage({super.key});

  @override
  DownloadWorkoutPageState createState() => DownloadWorkoutPageState();
}

class DownloadWorkoutPageState extends State<DownloadWorkoutPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  WorkoutPlan? _downloadedPlan;
  bool _isLoading = false;
  String? _error;

  Future<void> _downloadWorkoutPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _downloadedPlan = null;
      _nameController.clear();
    });

    try {
      String inputUrl = _urlController.text.trim();

      // Ensure URL starts with "http" or "https"
      if (!inputUrl.startsWith("http")) {
        inputUrl = "https://$inputUrl"; // Auto-fix if missing scheme
      }

      final uri = Uri.tryParse(inputUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        throw Exception("Invalid URL format. Ensure it starts with http:// or https://");
      }

      final response = await http.get(uri);
      if (!mounted) return;

      if (response.statusCode == 200) {
        debugPrint("🔍 API Response: ${response.body}");

        final dynamic data = jsonDecode(response.body);

        if (data is! Map) {
          throw Exception("Unexpected JSON format: Not an object.");
        }

        // Detect JSON structure dynamically
        String? planName = data["name"] ?? data["title"] ?? data["workout_name"];
        List<dynamic>? exercisesData = data["exercises"] ?? data["items"] ?? data["routine"];

        if (planName == null || exercisesData == null) {
          throw Exception("Workout plan is missing essential fields.");
        }

        // Convert exercise list dynamically
        List<Exercise> exercises = exercisesData.map((e) {
          if (e is Map<String, dynamic>) {
            return Exercise(
              name: e["name"] ?? e["exercise_name"] ?? "Unnamed Exercise",
              targetOutput: e["targetOutput"] ?? e["goal"] ?? e["reps"] ?? 0,
              unit: e["unit"] ?? e["measurement"] ?? "reps",
            );
          } else {
            throw Exception("Malformed exercise data.");
          }
        }).toList();

        // Create workout plan object
        WorkoutPlan plan = WorkoutPlan(name: planName, exercises: exercises);

        if (mounted) {
          setState(() {
            _downloadedPlan = plan;
            _nameController.text = planName; // Prefill workout name for editing
          });
        }
      } else {
        throw Exception("Failed to fetch workout plan. HTTP ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWorkoutPlan() async {
    if (_downloadedPlan != null) {
      String updatedName = _nameController.text.trim();

      if (updatedName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout plan name cannot be empty!')),
        );
        return;
      }

      // Create new workout plan with updated name
      WorkoutPlan newPlan = WorkoutPlan(
        name: updatedName,
        exercises: _downloadedPlan!.exercises,
      );

      List<WorkoutPlan> existingPlans = await _dbHelper.getWorkoutPlans();
      bool exists = existingPlans.any((plan) => plan.name == updatedName);

      if (!exists) {
        await _dbHelper.insertWorkoutPlan(newPlan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout plan saved successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout plan with this name already exists! Try renaming.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Workout Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Workout Plan URL',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _urlController.clear(),
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _downloadWorkoutPlan,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Download'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_downloadedPlan != null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Workout Plan Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Downloaded Plan: ${_downloadedPlan!.name}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _downloadedPlan!.exercises.length,
                  itemBuilder: (context, index) {
                    final e = _downloadedPlan!.exercises[index];
                    return ListTile(
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${e.targetOutput} ${e.unit}"),
                      leading: const Icon(Icons.fitness_center, color: Colors.blueAccent),
                    );
                  },
                ),
              ),
              ElevatedButton.icon(
                onPressed: _saveWorkoutPlan,
                icon: const Icon(Icons.save),
                label: const Text("Save Plan"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
