import 'package:flutter/material.dart';
import 'core/data/local_session_store.dart';
import 'core/data/session_model.dart';
import 'core/exercise/exercise_catalog.dart';
import 'features/pose_check/live_squat_check_page.dart';
import 'features/pose_check/live_exercise_check_page.dart';
import 'features/progress/progress_page.dart';

const _purple = Color(0xFF6C5CE7);
const _purpleDark = Color(0xFF5140C4);
const _ink = Color(0xFF17151F);
const _muted = Color(0xFF777382);
const _bg = Color(0xFFF7F6FA);

void main() => runApp(const PoseApp());

class PoseApp extends StatelessWidget {
  const PoseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Pose',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: _bg,
          colorScheme: ColorScheme.fromSeed(seedColor: _purple),
          fontFamily: 'Roboto',
          navigationBarTheme: const NavigationBarThemeData(
            height: 72,
            backgroundColor: Colors.white,
            indicatorColor: Color(0xFFEAE6FF),
            labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  final store = LocalSessionStore.instance;

  @override
  void initState() {
    super.initState();
    store.addListener(_refresh);
    store.load();
  }

  void _refresh() { if (mounted) setState(() {}); }

  Future<void> openExercise(String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => id == 'squat'
            ? const LiveSquatCheckPage()
            : LiveExerciseCheckPage(exerciseId: id),
      ),
    );
    await store.load();
    if (mounted) setState(() {});
  }

  @override
  void dispose() { store.removeListener(_refresh); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Home(sessions: store.sessions, onStart: () => openExercise('squat')),
      _Train(onStart: openExercise),
      ProgressPage(sessions: store.sessions),
      const _Profile(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
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

class _Home extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final VoidCallback onStart;
  const _Home({required this.sessions, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = sessions.where((s) => s.completedAt.year == now.year && s.completedAt.month == now.month && s.completedAt.day == now.day).length;
    final todayReps = sessions.where((s) => s.completedAt.year == now.year && s.completedAt.month == now.month && s.completedAt.day == now.day).fold<int>(0, (a, s) => a + s.reps);
    final best = sessions.isEmpty ? 0 : sessions.map((s) => s.bestScore).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('YOUR TRAINING SPACE', style: TextStyle(color: _purple, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
            SizedBox(height: 5),
            Text('Ready to move?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink)),
          ])),
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE8E5F0))), child: const Icon(Icons.person_outline_rounded, color: _ink)),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_purpleDark, Color(0xFF8B79FF)]), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Color(0x227B68EE), blurRadius: 24, offset: Offset(0, 12))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 8), const Text('ON-DEVICE FORM CHECK', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2))]),
            const SizedBox(height: 15),
            const Text('Move better.\nFeel stronger.', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.04)),
            const SizedBox(height: 10),
            const Text('Real-time movement feedback, processed on your device.', style: TextStyle(color: Colors.white70, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start with squat', style: TextStyle(fontWeight: FontWeight.w900)), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _purpleDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
          ]),
        ),
        const SizedBox(height: 26),
        const _SectionTitle('Today', action: 'Your activity'),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _Metric('$today', 'Sessions', Icons.bolt_rounded)), const SizedBox(width: 10), Expanded(child: _Metric('$todayReps', 'Reps', Icons.repeat_rounded)), const SizedBox(width: 10), Expanded(child: _Metric('$best', 'Best score', Icons.emoji_events_outlined))]),
        const SizedBox(height: 28),
        const _SectionTitle('Quick start', action: '3 movements'),
        const SizedBox(height: 12),
        ...exerciseCatalog.map((item) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _MiniExercise(item: item, onTap: () => item.id == 'squat' ? onStart() : Navigator.push(context, MaterialPageRoute(builder: (_) => LiveExerciseCheckPage(exerciseId: item.id))))),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFEFEAFF), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.shield_outlined, color: _purple, size: 20), SizedBox(width: 10), Expanded(child: Text('Privacy first — workout analysis stays on your device.', style: TextStyle(color: _ink, fontSize: 12, fontWeight: FontWeight.w700, height: 1.35)))])),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title, action;
  const _SectionTitle(this.title, {required this.action});
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink))), Text(action, style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700))]);
}

class _Metric extends StatelessWidget {
  final String value, label; final IconData icon;
  const _Metric(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(10, 14, 8, 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEDEAF2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _purple, size: 18), const SizedBox(height: 9), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 9, color: _muted, fontWeight: FontWeight.w700))]));
}

class _MiniExercise extends StatelessWidget {
  final ExerciseCatalogItem item; final VoidCallback onTap;
  const _MiniExercise({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(elevation: 0, color: Colors.white, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFEDEAF2))), child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(15)), child: Icon(item.icon, color: _purple)), title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, color: _ink)), subtitle: Text(item.subtitle, style: const TextStyle(color: _muted, fontSize: 12)), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: _muted)));
}

class _Train extends StatelessWidget {
  final Future<void> Function(String) onStart;
  const _Train({required this.onStart});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 28), children: [const Text('Train', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 6), const Text('Choose a movement and get live form feedback.', style: TextStyle(color: _muted)), const SizedBox(height: 22), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(25)), child: const Row(children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFFB9ADFF)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LIVE COACHING', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)), SizedBox(height: 5), Text('Pick a movement.\nFocus on your form.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.2))]))])), const SizedBox(height: 26), const Text('Movements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 12), ...exerciseCatalog.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _TrainCard(item: e, onTap: () => onStart(e.id))))]);
}

class _TrainCard extends StatelessWidget {
  final ExerciseCatalogItem item; final VoidCallback onTap;
  const _TrainCard({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(elevation: 0, color: Colors.white, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFEDEAF2))), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFFEDEAFF), borderRadius: BorderRadius.circular(18)), child: Icon(item.icon, color: _purple, size: 28)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 4), Text(item.description, style: const TextStyle(color: _muted, fontSize: 13, height: 1.3))])), Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFF4F2FA), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_forward_rounded, size: 18, color: _ink))]))));
}

class _Profile extends StatelessWidget {
  const _Profile();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 28), children: [const Text('Profile', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink)), const SizedBox(height: 6), const Text('Your training space.', style: TextStyle(color: _muted)), const SizedBox(height: 22), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_purpleDark, Color(0xFF8B79FF)]), borderRadius: BorderRadius.circular(26)), child: const Row(children: [CircleAvatar(radius: 29, backgroundColor: Colors.white24, child: Icon(Icons.person_rounded, color: Colors.white, size: 30)), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Welcome to Pose', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('Train with better form', style: TextStyle(color: Colors.white70))]))])), const SizedBox(height: 20), const _ProfileRow(Icons.flag_outlined, 'Training goal', 'Build better movement'), const _ProfileRow(Icons.accessibility_new_rounded, 'Focus', 'Form & technique'), const _ProfileRow(Icons.shield_outlined, 'Privacy', 'On-device first')]);
}

class _ProfileRow extends StatelessWidget {
  final IconData icon; final String title, value;
  const _ProfileRow(this.icon, this.title, this.value);
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEDEAF2))), child: Row(children: [Icon(icon, color: _purple), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _muted, fontSize: 12)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800))])), const Icon(Icons.chevron_right_rounded, color: _muted)]));
}
