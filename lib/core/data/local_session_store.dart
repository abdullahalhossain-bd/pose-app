import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_model.dart';

class LocalSessionStore extends ChangeNotifier {
  static const _key = 'pose.workout_sessions.v1';
  static const _maxSessions = 200;

  List<WorkoutSession> _sessions = const [];
  bool _loaded = false;

  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    final parsed = <WorkoutSession>[];
    for (final value in raw) {
      try {
        parsed.add(WorkoutSession.decode(value));
      } catch (_) {}
    }
    parsed.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    _sessions = parsed;
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(WorkoutSession session) async {
    await load();
    _sessions = [session, ..._sessions].take(_maxSessions).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _sessions.map((s) => s.encode()).toList());
    notifyListeners();
  }

  Future<void> clear() async {
    await load();
    _sessions = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }
}
