import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/splash_screen.dart';
import 'views/download_workout_page.dart';
import 'views/workout_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await _signInAnonymously();
    runApp(const MyApp());
  } catch (e) {
    debugPrint(" Firebase initialization failed: $e");
  }
}

Future<void> _signInAnonymously() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      debugShowCheckedModeBanner: false, // Removes debug banner
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      routes: {
        '/download': (context) => const DownloadWorkoutPage(),
        '/select': (context) => const WorkoutSelectionPage(),
      },
    );
  }
}
