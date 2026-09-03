import 'package:flutter/material.dart';

import 'features/pose_check/pose_check_page.dart';

void main() {
  runApp(const PoseApp());
}

class PoseApp extends StatelessWidget {
  const PoseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pose',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = <Widget>[
    _Dashboard(),
    _WorkoutsPage(),
    _ProgressPage(),
    _ProfilePage(),
  ];

  void _openPoseCheck() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PoseCheckPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workouts'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _dashboard() => _Dashboard(onStartPoseCheck: _openPoseCheck);
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({this.onStartPoseCheck});
  final VoidCallback? onStartPoseCheck;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const Text('Good morning 👋', style: TextStyle(fontSize: 15, color: Colors.black54)),
        const SizedBox(height: 4),
        const Text('Ready to move?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('POSE CHECK', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            const Text('Improve your form\nwith smart feedback.', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Color(0xFF5A4BCF)),
              onPressed: onStartPoseCheck,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Start pose check'),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('Today', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: _MetricCard(value: '0', label: 'Sessions', icon: Icons.timer_outlined)),
          SizedBox(width: 12),
          Expanded(child: _MetricCard(value: '0', label: 'Minutes', icon: Icons.schedule_outlined)),
          SizedBox(width: 12),
          Expanded(child: _MetricCard(value: '—', label: 'Score', icon: Icons.stars_outlined)),
        ]),
        const SizedBox(height: 26),
        const Text('Recommended', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const _WorkoutTile(title: 'Full Body Basics', subtitle: 'Beginner • 15 min', icon: Icons.accessibility_new),
        const _WorkoutTile(title: 'Squat Form', subtitle: 'Technique • 8 min', icon: Icons.directions_run),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _MetricCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [Icon(icon, color: Color(0xFF6C5CE7)), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))]),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _WorkoutTile({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(backgroundColor: const Color(0xFFECE9FF), child: Icon(icon, color: const Color(0xFF6C5CE7))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _WorkoutsPage extends StatelessWidget {
  const _WorkoutsPage();
  @override
  Widget build(BuildContext context) => const _SimplePage(title: 'Workouts', icon: Icons.fitness_center, message: 'Your exercise library will live here.');
}

class _ProgressPage extends StatelessWidget {
  const _ProgressPage();
  @override
  Widget build(BuildContext context) => const _SimplePage(title: 'Progress', icon: Icons.insights, message: 'Pose scores, consistency and improvement will appear here.');
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) => const _SimplePage(title: 'Profile', icon: Icons.person, message: 'Account and preferences will live here.');
}

class _SimplePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  const _SimplePage({required this.title, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: const Color(0xFF6C5CE7)), const SizedBox(height: 18), Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 16))])));
  }
}
