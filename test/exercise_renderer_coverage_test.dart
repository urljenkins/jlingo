import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/exercise_type_info.dart';
import 'package:lingua_sprint/widgets/exercises/exercise_renderer_registry.dart';

void main() {
  test('every exercise type has a registered renderer', () {
    // A missing renderer shows "No renderer registered for ..." mid-lesson
    // rather than failing at build time, so it has to be caught here.
    for (final type in ExerciseType.values) {
      final widget = ExerciseRendererRegistry.render(
        exercise: Exercise(
          id: 't',
          type: type,
          question: 'q',
          options: const ['a', 'b'],
          correctAnswer: 'a',
        ),
        onAnswer: (_) {},
      );
      expect(widget, isNotNull, reason: '$type has no renderer');
    }
  });

  test('every exercise type is described in the catalogue', () {
    expect(ExerciseTypeInfo.all.length, ExerciseType.values.length);
    expect(
      ExerciseTypeInfo.all.map((i) => i.type).toSet(),
      ExerciseType.values.toSet(),
    );
  });
}
