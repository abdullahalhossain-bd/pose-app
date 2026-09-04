import 'package:flutter/material.dart';
import '../../core/data/local_session_store.dart';
import '../../core/data/session_model.dart';
import '../../core/exercise/exercise_catalog.dart';
import 'live_squat_check_page.dart';
import 'live_exercise_check_page.dart';

const _purple = Color(0xFF6C5CE7), _purpleDark = Color(0xFF5140C4), _ink = Color(0xFF17151F), _muted = Color(0xFF777382);

class SessionCompletePage extends StatefulWidget {
  final String exercise;
  final int reps, score, bestScore;
  final List<int> repScores;
  final DateTime? completedAt;
  final int durationSeconds;
  const SessionCompletePage({super.key, this.exercise = 'squat', required this.reps, required this.score, required this.bestScore, this.repScores = const [], this.completedAt, this.durationSeconds = 0});
  @override State<SessionCompletePage> createState() => _SessionCompletePageState();
}

class _SessionCompletePageState extends State<SessionCompletePage> with SingleTickerProviderStateMixin {
  static final _store = LocalSessionStore.instance;
  bool _saved = false;
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  ExerciseCatalogItem get item => exerciseById(widget.exercise);
  String get label => widget.score >= 90 ? 'Excellent session' : widget.score >= 75 ? 'Strong work' : widget.score >= 55 ? 'Good start' : 'Keep practicing';

  @override void initState() { super.initState(); _save(); }
  @override void dispose() { _intro.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_saved || widget.reps <= 0) return;
    _saved = true;
    final scores = widget.repScores.isNotEmpty ? List<int>.from(widget.repScores) : List<int>.filled(widget.reps, widget.score);
    await _store.add(WorkoutSession(exercise: widget.exercise, reps: widget.reps, averageScore: widget.score.clamp(0, 100), bestScore: widget.bestScore.clamp(0, 100), repScores: scores, completedAt: widget.completedAt ?? DateTime.now(), durationSeconds: widget.durationSeconds));
  }

  Future<void> _trainAgain() async => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.exercise == 'squat' ? const LiveSquatCheckPage() : LiveExerciseCheckPage(exerciseId: widget.exercise)));

  @override Widget build(BuildContext context) {
    final has = widget.reps > 0;
    final curve = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    return Scaffold(backgroundColor: const Color(0xFFF8F7FC), body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FadeTransition(opacity: curve, child: Row(children: [IconButton(tooltip: 'Close results', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)), const Expanded(child: Text('SESSION COMPLETE', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: _muted))), const SizedBox(width: 48)])),
      const SizedBox(height: 10),
      ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(curve), child: FadeTransition(opacity: curve, child: Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(22, 24, 22, 22), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_purpleDark, Color(0xFF8B79FF)]), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Color(0x337B68EE), blurRadius: 28, offset: Offset(0, 12))]), child: Column(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(18)), child: Icon(item.icon, color: Colors.white, size: 28)), const SizedBox(height: 13),
        Text(item.name.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)), const SizedBox(height: 5), const Text('Your form score', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4),
        TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: widget.score.toDouble()), duration: const Duration(milliseconds: 850), curve: Curves.easeOutCubic, builder: (_, value, __) => Text(value.round().toString(), style: const TextStyle(color: Colors.white, fontSize: 64, height: .98, fontWeight: FontWeight.w900))),
        const Text('/100', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 12),
        AnimatedSwitcher(duration: const Duration(milliseconds: 350), transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)), child: Container(key: ValueKey(label), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.white18, borderRadius: BorderRadius.circular(30)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)))),
      ]))),
      const SizedBox(height: 22), const Text('SESSION SNAPSHOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: _muted)), const SizedBox(height: 10),
      FadeTransition(opacity: curve, child: Row(children: [Expanded(child: _StatCard(Icons.repeat_rounded, '${widget.reps}', 'Reps')), const SizedBox(width: 10), Expanded(child: _StatCard(Icons.emoji_events_rounded, has ? '${widget.bestScore}' : '—', 'Best')), const SizedBox(width: 10), Expanded(child: _StatCard(Icons.trending_up_rounded, has ? '${widget.score}' : '—', 'Average'))])),
      const SizedBox(height: 22),
      FadeTransition(opacity: curve, child: Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE8E5F0))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.auto_awesome_rounded, color: _purple)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Next focus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 5), Text(has ? (widget.score >= 75 ? 'Keep this movement consistent across every rep.' : 'Focus on controlled movement and a steady pattern next time.') : 'Step back, keep your whole body visible, and try again.', style: const TextStyle(color: _muted, fontSize: 13, height: 1.4))]))])),
      const SizedBox(height: 20), if (_saved) const Center(child: Padding(padding: EdgeInsets.only(bottom: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, size: 15, color: _purple), SizedBox(width: 5), Text('Saved on this device', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700))]))),
      TweenAnimationBuilder<double>(tween: Tween(begin: .96, end: 1), duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack, builder: (_, scale, child) => Transform.scale(scale: scale, child: child), child: SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: _trainAgain, icon: const Icon(Icons.replay_rounded), label: Text('Train ${item.name.toLowerCase()} again', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), style: FilledButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))))),
      const SizedBox(height: 10), SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, size: 19), label: const Text('Back to training', style: TextStyle(fontWeight: FontWeight.w800)), style: OutlinedButton.styleFrom(foregroundColor: _ink, side: const BorderSide(color: Color(0xFFDCD8E7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
      const SizedBox(height: 14), const Center(child: Text('Results are processed and stored locally on your device.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9995A3), fontSize: 10.5))),
    ])));
  }
}

class _StatCard extends StatelessWidget { final IconData icon; final String value, label; const _StatCard(this.icon, this.value, this.label); @override Widget build(BuildContext context) => TweenAnimationBuilder<double>(tween: Tween(begin: .92, end: 1), duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, builder: (_, scale, child) => Transform.scale(scale: scale, child: child), child: Container(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E5F0))), child: Column(children: [Icon(icon, color: _purple, size: 19), const SizedBox(height: 7), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 2), Text(label, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700))]))); }
