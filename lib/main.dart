import 'package:flutter/material.dart';
import 'features/pose_check/live_squat_check_page.dart';

const _purple = Color(0xFF6C5CE7);
const _ink = Color(0xFF17151F);
const _muted = Color(0xFF777382);
const _surface = Color(0xFFFFFFFF);

void main() => runApp(const PoseApp());

class PoseApp extends StatelessWidget {
  const PoseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Pose',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F6FA),
          colorScheme: ColorScheme.fromSeed(seedColor: _purple),
          fontFamily: 'sans',
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  void openCheck() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveSquatCheckPage()));
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _Dashboard(onStart: openCheck),
      _WorkoutsPage(onStart: openCheck),
      const _ProgressPage(),
      const _ProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: _surface,
        indicatorColor: const Color(0xFFEAE6FF),
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center_rounded), label: 'Train'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onStart});
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('TODAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _purple, letterSpacing: 1.4)),
              SizedBox(height: 5),
              Text('Ready to move?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.7)),
            ])),
            Container(width: 46, height: 46, decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.notifications_none_rounded, color: _ink)),
          ]),
          const SizedBox(height: 22),
          _HeroCard(onStart: onStart),
          const SizedBox(height: 26),
          const _SectionHeader(title: 'Today', action: 'See all'),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(child: _Metric(value: '0', label: 'Sessions', icon: Icons.local_fire_department_outlined)),
            SizedBox(width: 10),
            Expanded(child: _Metric(value: '0', label: 'Minutes', icon: Icons.schedule_rounded)),
            SizedBox(width: 10),
            Expanded(child: _Metric(value: '—', label: 'Best score', icon: Icons.auto_awesome_outlined)),
          ]),
          const SizedBox(height: 28),
          const _SectionHeader(title: 'Start training', action: ''),
          const SizedBox(height: 12),
          _TrainingCard(title: 'Squat form', subtitle: 'Technique • 8 min', icon: Icons.directions_run_rounded, onTap: onStart),
          _TrainingCard(title: 'Full body basics', subtitle: 'Beginner • 15 min', icon: Icons.accessibility_new_rounded, onTap: onStart),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFEFEAFF), borderRadius: BorderRadius.circular(22)),
            child: const Row(children: [
              Icon(Icons.lightbulb_outline_rounded, color: _purple), SizedBox(width: 12),
              Expanded(child: Text('Tip: keep your full body visible for more accurate feedback.', style: TextStyle(color: _ink, fontWeight: FontWeight.w600, height: 1.3))),
            ]),
          ),
        ],
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onStart});
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5E4AD7), Color(0xFF8B79FF)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: _purple.withValues(alpha: .20), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(30)), child: const Text('AI FORM CHECK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1))),
            const Spacer(),
            const Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 20),
          ]),
          const SizedBox(height: 18),
          const Text('Move better.\nFeel stronger.', style: TextStyle(color: Colors.white, fontSize: 30, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -0.7)),
          const SizedBox(height: 10),
          const Text('Get instant feedback on your exercise form using your camera.', style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.camera_alt_rounded), label: const Text('Check my form'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _purple, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
        ]),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});
  final String title, action;
  @override
  Widget build(BuildContext context) => Row(children: [Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _ink)), const Spacer(), if (action.isNotEmpty) Text(action, style: const TextStyle(color: _purple, fontWeight: FontWeight.w700, fontSize: 13))]);
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final String value, label; final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 13),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEDEAF2))),
        child: Column(children: [Icon(icon, size: 20, color: _purple), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600))]),
      );
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title, subtitle; final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        color: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFEDEAF2))),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: _purple, size: 27)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _ink)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13))])),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _muted),
          ])),
        ),
      );
}

class _WorkoutsPage extends StatelessWidget {
  const _WorkoutsPage({required this.onStart}); final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const Text('Train', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 6), const Text('Choose a movement and let Pose guide your form.', style: TextStyle(color: _muted)), const SizedBox(height: 22), _TrainingCard(title: 'Squat form', subtitle: 'Real-time knee & movement feedback', icon: Icons.directions_run_rounded, onTap: onStart), _TrainingCard(title: 'Full body basics', subtitle: 'Beginner movement session', icon: Icons.accessibility_new_rounded, onTap: onStart)]);
}
class _ProgressPage extends StatelessWidget { const _ProgressPage(); @override Widget build(BuildContext context) => const _SimplePage('Progress', Icons.insights_rounded, 'Your scores, reps and consistency will appear here after your first session.'); }
class _ProfilePage extends StatelessWidget { const _ProfilePage(); @override Widget build(BuildContext context) => const _SimplePage('Profile', Icons.person_rounded, 'Account and training preferences will live here.'); }
class _SimplePage extends StatelessWidget { const _SimplePage(this.title, this.icon, this.message); final String title, message; final IconData icon; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 88, height: 88, decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(28)), child: Icon(icon, size: 42, color: _purple)), const SizedBox(height: 22), Text(title, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 15, height: 1.45))]))); }
