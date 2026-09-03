import 'package:flutter/material.dart';
import 'features/pose_check/live_squat_check_page.dart';

void main() => runApp(const PoseApp());

class PoseApp extends StatelessWidget {
  const PoseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Pose', debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)), scaffoldBackgroundColor: const Color(0xFFF8F7FC)), home: const HomePage());
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }
class _HomePageState extends State<HomePage> {
  int index = 0;
  void openCheck() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveSquatCheckPage()));
  @override Widget build(BuildContext context) {
    final pages = <Widget>[_Dashboard(onStart: openCheck), const _SimplePage('Workouts', Icons.fitness_center, 'Your exercise library will live here.'), const _SimplePage('Progress', Icons.insights, 'Pose scores and improvement will appear here.'), const _SimplePage('Profile', Icons.person, 'Account and preferences will live here.')];
    return Scaffold(body: SafeArea(child: pages[index]), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workouts'), NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'), NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile')]));
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onStart}); final VoidCallback onStart;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20,18,20,24), children: [const Text('Good morning 👋', style: TextStyle(fontSize: 15, color: Colors.black54)), const SizedBox(height: 4), const Text('Ready to move?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 24), Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)]), borderRadius: BorderRadius.all(Radius.circular(28))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('POSE CHECK', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1.2)), const SizedBox(height: 10), const Text('Improve your form\nwith smart feedback.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)), const SizedBox(height: 18), FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Start pose check'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Color(0xFF5A4BCF)))])), const SizedBox(height: 24), const Text('Today', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 12), const Row(children: [Expanded(child: _Metric('0','Sessions')), SizedBox(width: 12), Expanded(child: _Metric('0','Minutes')), SizedBox(width: 12), Expanded(child: _Metric('—','Score'))])]);
}
class _Metric extends StatelessWidget { const _Metric(this.value,this.label); final String value,label; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical:16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))), child: Column(children: [Text(value, style: const TextStyle(fontSize:21,fontWeight:FontWeight.w800)), const SizedBox(height:3), Text(label, style: const TextStyle(fontSize:12,color:Colors.black54))])); }
class _SimplePage extends StatelessWidget { const _SimplePage(this.title,this.icon,this.message); final String title,message; final IconData icon; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon,size:64,color:const Color(0xFF6C5CE7)), const SizedBox(height:18), Text(title,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800)), const SizedBox(height:8), Text(message,textAlign:TextAlign.center,style:const TextStyle(color:Colors.black54,fontSize:16))]))); }
