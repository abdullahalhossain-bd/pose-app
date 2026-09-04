import 'package:flutter/material.dart';
import '../../core/data/local_session_store.dart';
import '../../core/data/session_model.dart';

const _purple = Color(0xFF6C5CE7);
const _ink = Color(0xFF17151F);
const _muted = Color(0xFF777382);

class SessionCompletePage extends StatefulWidget {
  final int reps;
  final int score;
  final int bestScore;
  final List<int> repScores;
  final DateTime? completedAt;
  final int durationSeconds;

  const SessionCompletePage({super.key, required this.reps, required this.score, required this.bestScore, this.repScores = const [], this.completedAt, this.durationSeconds = 0});

  @override
  State<SessionCompletePage> createState() => _SessionCompletePageState();
}

class _SessionCompletePageState extends State<SessionCompletePage> {
  static final LocalSessionStore _store = LocalSessionStore();
  bool _saved = false;

  String get label => widget.score >= 90 ? 'Excellent session' : widget.score >= 75 ? 'Strong work' : widget.score >= 55 ? 'Good start' : 'Keep practicing';

  @override
  void initState() {
    super.initState();
    _saveSession();
  }

  Future<void> _saveSession() async {
    if (_saved) return;
    _saved = true;
    final scores = widget.repScores.isNotEmpty ? List<int>.from(widget.repScores) : (widget.reps > 0 ? List<int>.filled(widget.reps, widget.score) : <int>[]);
    await _store.add(WorkoutSession(exercise: 'squat', reps: widget.reps, averageScore: widget.score, bestScore: widget.bestScore, repScores: scores, completedAt: widget.completedAt ?? DateTime.now(), durationSeconds: widget.durationSeconds));
  }

  @override
  Widget build(BuildContext context) {
    final hasReps = widget.reps > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Semantics(label: 'Close session summary', button: true, child: IconButton(onPressed: () => Navigator.pop(context), tooltip: 'Close', icon: const Icon(Icons.close_rounded))), const Expanded(child: Text('Session complete', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink))), const SizedBox(width: 48)]),
            const SizedBox(height: 14),
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7B68EE), Color(0xFF5140C4)]), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x337B68EE), blurRadius: 28, offset: Offset(0, 12))]), child: Column(children: [const Text('SQUAT FORM SCORE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const SizedBox(height: 8), Text('${widget.score}', style: const TextStyle(color: Colors.white, fontSize: 64, height: .95, fontWeight: FontWeight.w900)), const Text('/100', style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(30)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))])),
            const SizedBox(height: 22),
            const Text('YOUR SESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: _muted)),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: _StatCard(icon: Icons.repeat_rounded, value: '${widget.reps}', label: 'Reps')), const SizedBox(width: 10), Expanded(child: _StatCard(icon: Icons.emoji_events_rounded, value: hasReps ? '${widget.bestScore}' : '—', label: 'Best score')), const SizedBox(width: 10), Expanded(child: _StatCard(icon: Icons.trending_up_rounded, value: hasReps ? '${widget.score}' : '—', label: 'Average'))]),
            const SizedBox(height: 24),
            Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE8E5F0))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.auto_awesome_rounded, color: _purple)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Your next focus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)), const SizedBox(height: 5), Text(hasReps ? (widget.score >= 75 ? 'Keep your depth and movement consistent across every rep.' : 'Focus on controlled depth and a steady movement pattern next time.') : 'Try again with your whole body visible and enough space around you.', style: const TextStyle(color: _muted, fontSize: 13, height: 1.4))]))]),
            const SizedBox(height: 26),
            SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.replay_rounded), label: const Text('Train again', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), style: FilledButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.insights_rounded, size: 20), label: const Text('View progress', style: TextStyle(fontWeight: FontWeight.w800)), style: OutlinedButton.styleFrom(foregroundColor: _ink, side: const BorderSide(color: Color(0xFFDCD8E7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
            const SizedBox(height: 12),
            const Center(child: Text('Results are processed and stored locally on your device.', style: TextStyle(color: Color(0xFF9995A3), fontSize: 11))),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E5F0))), child: Column(children: [Icon(icon, color: _purple, size: 20), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700)]));
}
