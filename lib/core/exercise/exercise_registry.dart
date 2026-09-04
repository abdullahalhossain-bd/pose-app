import 'exercise_definition.dart';
import 'push_up_analyzer.dart';
import 'lunge_analyzer.dart';

class ExerciseRegistry {
  static final Map<String, ExerciseAnalyzer Function()> _factories = {
    'push_up': () => PushUpAnalyzer(),
    'lunge': () => LungeAnalyzer(),
  };

  static List<String> get ids => _factories.keys.toList(growable: false);

  static ExerciseAnalyzer create(String id) {
    final factory = _factories[id];
    if (factory == null) {
      throw ArgumentError('Unsupported exercise: $id');
    }
    return factory();
  }
}
