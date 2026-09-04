import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/data/session_model.dart';
import '../../core/exercise/exercise_catalog.dart';

const _purple = Color(0xFF6C5CE7), _ink = Color(0xFF17151F), _muted = Color(0xFF777382), _soft = Color(0xFFEDEAFF);

class ProgressPage extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const ProgressPage({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final reps = sessions.fold<int>(0, (a, s) => a + s.reps);
    final best = sessions.isEmpty ? null : sessions.map((s) => s.bestScore).reduce(math.max);
    final avg = sessions.isEmpty ? null : (sessions.map((s) => s.averageScore).reduce((a, b) => a + b) / sessions.length).round();
    final recent = sessions.take(8).toList();
    final activeDays = sessions.map((s) => '${s.completedAt.year}-${s.completedAt.month}-${s.completedAt.day}').toSet().length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text('Progress', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 6),
        const Text('See how your movement improves over time.', style: TextStyle(color: _muted)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(26)),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.insights_rounded, color: Color(0xFFC2B8FF))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('YOUR JOURNEY', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.3)),
              const SizedBox(height: 5),
              Text(activeDays == 0 ? 'Start your first session' : '$activeDays active day${activeDays == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(sessions.isEmpty ? 'Your first workout will appear here.' : 'Every session is saved locally on this device.', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 22),
        const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFEDEAF2))), child: Row(children: [
          _Stat('${sessions.length}', 'Sessions'), _Divider(), _Stat('$reps', 'Reps'), _Divider(), _Stat(best == null ? '—' : '$best', 'Best'), _Divider(), _Stat(avg == null ? '—' : '$avg', 'Average'),
        ])),
        const SizedBox(height: 26),
        const Text('Exercises', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 12),
        ...exerciseCatalog.map((e) => _ExerciseRow(item: e, sessions: sessions.where((s) => s.exercise == e.id).toList())),
        const SizedBox(height: 18),
        const Text('Recent sessions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 12),
        if (recent.isEmpty) const _Empty() else ...recent.map((s) => _Session(s)),
      ],
    );
  }
}

class _Divider extends StatelessWidget { const _Divider(); @override Widget build(BuildContext c) => Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 6), color: const Color(0xFFEDEAF2)); }
class _Stat extends StatelessWidget { final String value, label; const _Stat(this.value, this.label); @override Widget build(BuildContext c) => Expanded(child: Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 9, color: _muted, fontWeight: FontWeight.w700))])); }

class _ExerciseRow extends StatelessWidget {
  final ExerciseCatalogItem item; final List<WorkoutSession> sessions;
  const _ExerciseRow({required this.item, required this.sessions});
  @override
  Widget build(BuildContext context) {
    final best = sessions.isEmpty ? 0 : sessions.map((s) => s.bestScore).reduce(math.max);
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEDEAF2))), child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(15)), child: Icon(item.icon, color: _purple)),
      const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 4), Text(sessions.isEmpty ? 'Ready when you are' : '${sessions.length} session${sessions.length == 1 ? '' : 's'} • best $best', style: const TextStyle(color: _muted, fontSize: 12))])),
      if (sessions.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(12)), child: Text('$best', style: const TextStyle(fontWeight: FontWeight.w900, color: _purple))),
    ]));
  }
}

class _Session extends StatelessWidget {
  final WorkoutSession session;
  const _Session(this.session);
  @override
  Widget build(BuildContext context) {
    final item = exerciseById(session.exercise);
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFEDEAF2))), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(14)), child: Icon(item.icon, color: _purple, size: 21)),
      const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 3), Text('${session.reps} reps • ${session.completedAt.day}/${session.completedAt.month}/${session.completedAt.year}', style: const TextStyle(color: _muted, fontSize: 11))])),
      Text('${session.averageScore}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: _ink)),
    ]));
  }
}

class _Empty extends StatelessWidget { const _Empty(); @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(22)), child: const Row(children: [Icon(Icons.show_chart_rounded, color: _purple), SizedBox(width: 12), Expanded(child: Text('Complete your first workout to unlock your progress history.', style: TextStyle(color: _ink, fontWeight: FontWeight.w700, height: 1.4)))])); }
