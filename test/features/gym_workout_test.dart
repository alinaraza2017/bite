import 'package:flutter_test/flutter_test.dart';

import 'package:bite/data/models/gym_models.dart';
import 'package:bite/data/repositories/gym_repository.dart';
import 'package:bite/domain/feature_gate.dart';

import '../data/test_database.dart';

void main() {
  test('a finished session stores the exercise burn and remembers the set', () async {
    final TestDatabase db = await openTestDatabase();
    final WorkoutRepository workouts = WorkoutRepository(db.database);
    final int exerciseId = await db.database.insert('exercises', {
      'name': 'Bench Press',
      'muscle_group': 'chest',
      'type': 'strength',
      'met': 5,
    });
    final int sessionId = await workouts.startSession(
      name: 'Push',
      exercises: [
        Exercise(
          id: exerciseId,
          name: 'Bench Press',
          muscleGroup: 'chest',
        ),
      ],
      isPremium: true,
    );

    final sets = await workouts.setsForSession(sessionId);
    await workouts.saveSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: 1,
      weightKg: 40,
      reps: 8,
      existingId: sets.single.id,
      isPremium: true,
    );
    final done = await workouts.finishSession(
      sessionId,
      profileWeightKg: 70,
    );
    // 5 MET x 70 kg x (120 seconds / 3600) = 12 kcal.
    expect(done.burnedKcal, 12);
    expect(done.totalSets, 1);
    expect(done.isFinished, isTrue);

    final previous = await workouts.previousSet(exerciseId);
    expect(previous!.weightKg, 40);
    expect(previous.reps, 8);
    await db.close();
  });

  test('a free account cannot save bench press', () async {
    final TestDatabase db = await openTestDatabase();
    final WorkoutRepository workouts = WorkoutRepository(db.database);
    final int benchId = await db.database.insert('exercises', {
      'name': 'Barbell Bench Press',
      'muscle_group': 'Chest',
      'type': 'strength',
      'met': 6,
      'is_free': 0,
    });
    final Exercise bench = Exercise(
      id: benchId,
      name: 'Barbell Bench Press',
      muscleGroup: 'Chest',
      met: 6,
    );
    expect(
      () => workouts.startSession(
        name: 'Push',
        exercises: <Exercise>[bench],
        isPremium: false,
      ),
      throwsA(isA<PremiumRequired>()),
    );

    final int sessionId = await workouts.startSession(
      name: 'Push',
      exercises: <Exercise>[bench],
      isPremium: true,
    );
    expect(
      () => workouts.saveSet(
        sessionId: sessionId,
        exerciseId: benchId,
        setNumber: 1,
        weightKg: 60,
        reps: 8,
        isPremium: false,
      ),
      throwsA(isA<PremiumRequired>()),
    );
    final sets = await workouts.setsForSession(sessionId);
    expect(sets.single.completed, isFalse);

    for (int number = 1; number <= 4; number++) {
      await workouts.saveSet(
        sessionId: sessionId,
        exerciseId: benchId,
        setNumber: number,
        weightKg: 60,
        reps: 8,
        existingId: number == 1 ? sets.single.id : null,
        isPremium: true,
      );
    }
    final done = await workouts.finishSession(sessionId, profileWeightKg: 70);
    expect(done.burnedKcal, 56);
    await db.close();
  });

  test('a free account can log walking', () async {
    final TestDatabase db = await openTestDatabase();
    final WorkoutRepository workouts = WorkoutRepository(db.database);
    final int walkingId = await db.database.insert('exercises', {
      'name': 'Walking',
      'muscle_group': 'Cardio',
      'type': 'duration',
      'met': 5,
      'is_free': 1,
    });
    final int sessionId = await workouts.startSession(
      name: 'Walking',
      exercises: <Exercise>[
        Exercise(
          id: walkingId,
          name: 'Walking',
          muscleGroup: 'Cardio',
          type: 'duration',
          met: 5,
          isFree: true,
        ),
      ],
    );
    final sets = await workouts.setsForSession(sessionId);
    await workouts.saveSet(
      sessionId: sessionId,
      exerciseId: walkingId,
      setNumber: 1,
      weightKg: 0,
      reps: 0,
      minutes: 30,
      existingId: sets.single.id,
    );
    final done = await workouts.finishSession(sessionId, profileWeightKg: 70);
    expect(done.burnedKcal, 175);
    await db.close();
  });
}
