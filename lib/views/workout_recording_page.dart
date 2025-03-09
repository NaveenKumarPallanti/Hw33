import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutRecordingPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;
  final String workoutType;

  const WorkoutRecordingPage({super.key, required this.workoutPlan, required this.workoutType});

  @override
  WorkoutRecordingPageState createState() => WorkoutRecordingPageState();
}

class WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  final Map<String, int> recordedOutputs = {};
  final Map<String, int> secondsElapsed = {};
  final Map<String, bool> isTiming = {};
  final Map<String, Timer?> timers = {};
  final Map<String, double> distanceInputs = {};
  String? inviteCode;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (widget.workoutType != "Solo") {
      _generateInviteCode();
    }
  }

  @override
  void dispose() {
    for (var timer in timers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  void _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final generatedCode = List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
    if (mounted) {
      setState(() {
        inviteCode = generatedCode;
      });
    }
  }

  Future<void> _saveWorkoutToFirestore() async {
    if (recordedOutputs.values.every((value) => value == 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot save an empty workout!')),
        );
      }
      return;
    }

    final workoutData = {
      'userId': userId,
      'workoutType': widget.workoutType,
      'workoutPlan': widget.workoutPlan.toMap(),
      'date': DateTime.now().toIso8601String(),
      'results': widget.workoutPlan.exercises.map((exercise) {
        return {
          'exercise': exercise.toMap(),
          'achievedOutput': recordedOutputs[exercise.name] ?? 0,
        };
      }).toList(),
    };

    if (widget.workoutType != "Solo") {
      workoutData['inviteCode'] = inviteCode ?? '';
    }

    await _firestore.collection('group_workouts').add(workoutData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.workoutType} Workout')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              widget.workoutPlan.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (widget.workoutType != "Solo" && inviteCode != null) ...[
              Text(
                "Invite Code: $inviteCode",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: inviteCode!,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.workoutPlan.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = widget.workoutPlan.exercises[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _buildExerciseInput(exercise),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveWorkoutToFirestore,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text(
                'Save Workout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseInput(Exercise exercise) {
    switch (exercise.unit) {
      case 'reps':
        return _buildStepperInput(exercise);
      case 'seconds':
        return _buildTimerInput(exercise);
      case 'meters':
        return _buildSliderInput(exercise);
      default:
        return const Text("Unknown exercise type");
    }
  }

  Widget _buildStepperInput(Exercise exercise) {
    recordedOutputs[exercise.name] ??= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(exercise.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  recordedOutputs[exercise.name] = (recordedOutputs[exercise.name]! - 1).clamp(0, 999);
                });
              },
            ),
            Text('${recordedOutputs[exercise.name]} reps', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  recordedOutputs[exercise.name] = (recordedOutputs[exercise.name]! + 1).clamp(0, 999);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerInput(Exercise exercise) {
    secondsElapsed[exercise.name] ??= 0;
    isTiming[exercise.name] ??= false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(exercise.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text('${secondsElapsed[exercise.name]} sec', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: Icon(isTiming[exercise.name]! ? Icons.stop : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  if (isTiming[exercise.name]!) {
                    timers[exercise.name]?.cancel();
                    recordedOutputs[exercise.name] = secondsElapsed[exercise.name]!;
                  } else {
                    secondsElapsed[exercise.name] = 0;
                    timers[exercise.name] = Timer.periodic(const Duration(seconds: 1), (timer) {
                      if (mounted) {
                        setState(() {
                          secondsElapsed[exercise.name] = secondsElapsed[exercise.name]! + 1;
                        });
                      }
                    });
                  }
                  isTiming[exercise.name] = !isTiming[exercise.name]!;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderInput(Exercise exercise) {
    distanceInputs[exercise.name] ??= 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${exercise.name} - ${distanceInputs[exercise.name]!.toInt()} meters',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Slider(
          min: 0,
          max: 1000,
          divisions: 20,
          value: distanceInputs[exercise.name]!,
          label: '${distanceInputs[exercise.name]!.toInt()} meters',
          onChanged: (newValue) {
            setState(() {
              distanceInputs[exercise.name] = newValue;
              recordedOutputs[exercise.name] = newValue.toInt();
            });
          },
        ),
      ],
    );
  }
}
