import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:hw33/views/workout_history_page.dart';
import 'package:hw33/views/workout_recording_page.dart';
import 'package:hw33/widgets/recent_performance_widget.dart';
import 'package:hw33/models/workout.dart';
import 'package:hw33/models/exercise.dart';
import 'package:hw33/models/exercise_result.dart';
import 'package:hw33/models/workout_plan.dart';
import 'widget_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollection;
  late MockDocumentReference<Map<String, dynamic>> mockDocument;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference<Map<String, dynamic>>();
    mockDocument = MockDocumentReference<Map<String, dynamic>>(); // ✅ FIXED

    when(mockFirestore.collection('group_workouts')).thenReturn(mockCollection);
    when(mockCollection.add(any)).thenAnswer((_) async => mockDocument as DocumentReference<Map<String, dynamic>>); // ✅ FIXED
    when(mockCollection.get()).thenAnswer((_) async => MockQuerySnapshot<Map<String, dynamic>>()); // ✅ FIXED
  });

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  testWidgets('WorkoutRecordingPage stores results in Firestore', (WidgetTester tester) async {
    WorkoutPlan mockPlan = WorkoutPlan(
      name: 'Custom Workout',
      exercises: [
        Exercise(name: 'Jump Rope', targetOutput: 50, unit: 'reps'),
        Exercise(name: 'Running', targetOutput: 1000, unit: 'meters'),
      ],
    );

    await tester.pumpWidget(createTestableWidget(WorkoutRecordingPage(workoutPlan: mockPlan, workoutType: 'Solo')));

    expect(find.byIcon(Icons.add), findsWidgets);
    expect(find.byIcon(Icons.remove), findsWidgets);
    expect(find.byType(Slider), findsWidgets);
  });

  testWidgets('WorkoutRecordingPage adds a workout and saves it to Firestore', (WidgetTester tester) async {
    WorkoutPlan mockPlan = WorkoutPlan(
      name: 'Dynamic Workout',
      exercises: [
        Exercise(name: 'Push-ups', targetOutput: 20, unit: 'reps'),
      ],
    );

    await tester.pumpWidget(createTestableWidget(WorkoutRecordingPage(workoutPlan: mockPlan, workoutType: 'Solo')));

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    verify(mockCollection.add(any)).called(1);
  });

  testWidgets('WorkoutHistoryPage retrieves recorded workouts from Firestore', (WidgetTester tester) async {
    when(mockCollection.get()).thenAnswer((_) async => MockQuerySnapshot<Map<String, dynamic>>());

    await tester.pumpWidget(createTestableWidget(WorkoutHistoryPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Workout History'), findsOneWidget);
  });

  testWidgets('Tapping a workout in history navigates to WorkoutDetailsPage', (WidgetTester tester) async {
    final workout = Workout(
      date: DateTime(2025, 2, 19),
      results: [
        ExerciseResult(
          exercise: Exercise(name: 'Dynamic Exercise 2', targetOutput: 15, unit: 'reps'),
          achievedOutput: 18,
        ),
      ],
    );

    when(mockCollection.get()).thenAnswer((_) async => MockQuerySnapshot<Map<String, dynamic>>());

    await tester.pumpWidget(createTestableWidget(WorkoutHistoryPage()));
    await tester.pumpAndSettle();

    final workoutFinder = find.text('2025-02-19');
    expect(workoutFinder, findsOneWidget);

    await tester.tap(workoutFinder);
    await tester.pumpAndSettle();

    expect(find.textContaining('Dynamic Exercise 2'), findsOneWidget);
  });

  testWidgets('RecentPerformanceWidget shows no workouts message when no recent workouts exist', (WidgetTester tester) async {
    when(mockCollection.get()).thenAnswer((_) async => MockQuerySnapshot<Map<String, dynamic>>());

    await tester.pumpWidget(createTestableWidget(const RecentPerformanceWidget()));

    expect(find.textContaining('No recent workouts'), findsOneWidget);
  });

  testWidgets('RecentPerformanceWidget shows number of workouts in the last 7 days', (WidgetTester tester) async {
    when(mockCollection.get()).thenAnswer((_) async => MockQuerySnapshot<Map<String, dynamic>>());

    await tester.pumpWidget(createTestableWidget(const RecentPerformanceWidget()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Exercises in last 7 days:'), findsOneWidget);
  });
}
