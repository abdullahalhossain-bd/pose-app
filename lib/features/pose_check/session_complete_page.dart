import 'package:flutter/material.dart';

class SessionCompletePage extends StatelessWidget {
  final int reps;
  final int score;
  final int bestScore;

  const SessionCompletePage({super.key, required this.reps, required this.score, required this.bestScore});

  String get label => score >= 90 ? 'Excellent session' : score >= 75 ? 'Strong work' : score >= 55 ? 'Good start' : 'Keep practicing';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              const Expanded(child: Text('Session complete', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7B68EE), Color(0xFF5D4ED0)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Color(0x337B68EE), blurRadius: 28, offset: Offset(0, 12))],
              ),
              child: Column(children: [
                const Text('SQUAT FORM SCORE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                const SizedBox(height: 8),
                Text('$score', style: const TextStyle(color: Colors.white, fontSize: 64, height: .95, fontWeight: FontWeight.w900)),
                const Text('/100', style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(30)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('YOUR SESSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: Color(0xFF777382))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _StatCard(icon: Icons.repeat_rounded, value: '$reps', label: 'Reps')),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(icon: Icons.emoji_events_rounded, value: '$bestScore', label: 'Best score')),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(icon: Icons.trending_up_rounded, value: '$score', label: 'Average')),
            ]),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE8E5F0))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6C5CE7))),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your next focus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(score >= 75 ? 'Keep your depth and movement consistent across every rep.' : 'Focus on controlled depth and a steady movement pattern next time.', style: const TextStyle(color: Color(0xFF777382), fontSize: 13, height: 1.4)),
                ])),
              ]),
            ),
            const SizedBox(height: 26),
            SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.replay_rounded), label: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))))),
            const SizedBox(height: 10),
            const Center(child: Text('Session results are currently shown locally.', style: TextStyle(color: Color(0xFF9995A3), fontSize: 11))),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E5F0))),
    child: Column(children: [Icon(icon, color: const Color(0xFF6C5CE7), size: 20), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF777382), fontSize: 10, fontWeight: FontWeight.w700))]),
  );
}
