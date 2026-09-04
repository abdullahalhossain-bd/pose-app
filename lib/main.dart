import 'package:flutter/material.dart';
import 'core/data/local_session_store.dart';
import 'core/data/session_model.dart';
import 'features/pose_check/live_squat_check_page.dart';
import 'features/progress/progress_page.dart';

const _purple = Color(0xFF6C5CE7);
const _purpleDark = Color(0xFF5140C4);
const _ink = Color(0xFF17151F);
const _muted = Color(0xFF777382);
const _surface = Colors.white;
const _bg = Color(0xFFF7F6FA);

void main() => runApp(const PoseApp());

class PoseApp extends StatelessWidget {
  const PoseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Pose', debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: _bg, colorScheme: ColorScheme.fromSeed(seedColor: _purple), fontFamily: 'sans'), home: const HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  final store = LocalSessionStore.instance;
  @override void initState() { super.initState(); store.addListener(_refresh); store.load(); }
  void _refresh() { if (mounted) setState(() {}); }
  Future<void> openCheck() async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveSquatCheckPage())); await store.load(); if (mounted) setState(() {}); }
  @override void dispose() { store.removeListener(_refresh); super.dispose(); }
  @override Widget build(BuildContext context) {
    final pages = [_Dashboard(onStart: openCheck, sessions: store.sessions), _WorkoutsPage(onStart: openCheck), ProgressPage(sessions: store.sessions), const _ProfilePage()];
    return Scaffold(body: SafeArea(child: pages[index]), bottomNavigationBar: NavigationBar(height: 74, backgroundColor: _surface, elevation: 0, indicatorColor: const Color(0xFFEAE6FF), selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center_rounded), label: 'Train'),
      NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Progress'),
      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
    ]));
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onStart, required this.sessions});
  final VoidCallback onStart; final List<WorkoutSession> sessions;
  @override Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = sessions.where((s) => s.completedAt.year == now.year && s.completedAt.month == now.month && s.completedAt.day == now.day).toList();
    final todayMinutes = today.fold<int>(0, (sum, s) => sum + (s.durationSeconds / 60).ceil());
    final best = sessions.isEmpty ? null : sessions.map((s) => s.bestScore).reduce((a, b) => a > b ? a : b);
    return ListView(padding: const EdgeInsets.fromLTRB(20,20,20,28), children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('TODAY', style: TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:_purple,letterSpacing:1.5)), SizedBox(height:5), Text('Ready to move?', style: TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:_ink,letterSpacing:-.8))])), Semantics(label:'Notifications',button:true,child:_IconButton(icon:Icons.notifications_none_rounded))]),
      const SizedBox(height:22), _HeroCard(onStart:onStart), const SizedBox(height:26), const _SectionHeader(title:'Today',action:'Overview'), const SizedBox(height:12),
      Row(children:[Expanded(child:_Metric(value:'${today.length}',label:'Sessions',icon:Icons.local_fire_department_outlined)),const SizedBox(width:10),Expanded(child:_Metric(value:'$todayMinutes',label:'Minutes',icon:Icons.schedule_rounded)),const SizedBox(width:10),Expanded(child:_Metric(value:best==null?'—':'$best',label:'Best score',icon:Icons.auto_awesome_outlined))]),
      const SizedBox(height:28), const _SectionHeader(title:'Start training',action:''), const SizedBox(height:12),
      _TrainingCard(title:'Squat form',subtitle:'Technique • 8 min',icon:Icons.directions_run_rounded,onTap:onStart,featured:true),
      _TrainingCard(title:'Full body basics',subtitle:'Beginner • 15 min',icon:Icons.accessibility_new_rounded,onTap:onStart), const SizedBox(height:8), const _TipCard(),
    ]);
  }
}

class _IconButton extends StatelessWidget { const _IconButton({required this.icon}); final IconData icon; @override Widget build(BuildContext context)=>Container(width:46,height:46,decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFEDEAF2))),child:Icon(icon,color:_ink)); }
class _TipCard extends StatelessWidget { const _TipCard(); @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:const Color(0xFFEFEAFF),borderRadius:BorderRadius.circular(22)),child:const Row(children:[Icon(Icons.lightbulb_outline_rounded,color:_purple),SizedBox(width:12),Expanded(child:Text('Tip: keep your full body visible and use good lighting for clearer feedback.',style:TextStyle(color:_ink,fontWeight:FontWeight.w600,height:1.35)))])); }
class _HeroCard extends StatelessWidget { const _HeroCard({required this.onStart}); final VoidCallback onStart; @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[_purpleDark,Color(0xFF8B79FF)]),borderRadius:BorderRadius.circular(30),boxShadow:[BoxShadow(color:_purple,blurRadius:26,offset:Offset(0,12))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(30)),child:const Text('AI FORM CHECK',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.1))),const Spacer(),const Icon(Icons.auto_awesome_rounded,color:Colors.white70,size:20)]),const SizedBox(height:18),const Text('Move better.\nFeel stronger.',style:TextStyle(color:Colors.white,fontSize:30,height:1.06,fontWeight:FontWeight.w900,letterSpacing:-.7)),const SizedBox(height:10),const Text('Real-time movement feedback from your camera — designed to be simple and understandable.',style:TextStyle(color:Colors.white70,fontSize:14,height:1.4)),const SizedBox(height:20),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:onStart,icon:const Icon(Icons.camera_alt_rounded),label:const Text('Check my form'),style:FilledButton.styleFrom(backgroundColor:Colors.white,foregroundColor:_purpleDark,padding:const EdgeInsets.symmetric(vertical:15),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),textStyle:const TextStyle(fontWeight:FontWeight.w900))))])); }
class _SectionHeader extends StatelessWidget { const _SectionHeader({required this.title,required this.action}); final String title,action; @override Widget build(BuildContext context)=>Row(children:[Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:_ink)),const Spacer(),if(action.isNotEmpty)Text(action,style:const TextStyle(color:_purple,fontWeight:FontWeight.w800,fontSize:13))]); }
class _Metric extends StatelessWidget { const _Metric({required this.value,required this.label,required this.icon}); final String value,label; final IconData icon; @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.fromLTRB(8,14,8,13),decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFEDEAF2))),child:Column(children:[Icon(icon,size:20,color:_purple),const SizedBox(height:8),Text(value,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:_ink)),const SizedBox(height:2),Text(label,textAlign:TextAlign.center,style:const TextStyle(fontSize:10,color:_muted,fontWeight:FontWeight.w700))])); }
class _TrainingCard extends StatelessWidget { const _TrainingCard({required this.title,required this.subtitle,required this.icon,required this.onTap,this.featured=false}); final String title,subtitle; final IconData icon; final VoidCallback onTap; final bool featured; @override Widget build(BuildContext context)=>Card(elevation:0,margin:const EdgeInsets.only(bottom:10),color:_surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),side:const BorderSide(color:Color(0xFFEDEAF2))),child:InkWell(borderRadius:BorderRadius.circular(20),onTap:onTap,child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Container(width:52,height:52,decoration:BoxDecoration(color:featured?const Color(0xFFE3DEFF):const Color(0xFFF0EEF5),borderRadius:BorderRadius.circular(16)),child:Icon(icon,color:_purple,size:27)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16,color:_ink)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:_muted,fontSize:13))])),const Icon(Icons.arrow_forward_ios_rounded,size:16,color:_muted)])))); }
class _WorkoutsPage extends StatelessWidget { const _WorkoutsPage({required this.onStart}); final VoidCallback onStart; @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(20,20,20,28),children:[const Text('Train',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:_ink)),const SizedBox(height:6),const Text('Choose a movement and let Pose guide your form.',style:TextStyle(color:_muted,fontSize:14)),const SizedBox(height:24),_WorkoutHero(onStart:onStart),const SizedBox(height:26),const Text('Movements',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:_ink)),const SizedBox(height:12),_TrainingCard(title:'Squat form',subtitle:'Real-time knee & movement feedback',icon:Icons.directions_run_rounded,onTap:onStart,featured:true),_TrainingCard(title:'Full body basics',subtitle:'Beginner • guided movement',icon:Icons.accessibility_new_rounded,onTap:onStart)]); }
class _WorkoutHero extends StatelessWidget { const _WorkoutHero({required this.onStart}); final VoidCallback onStart; @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_ink,borderRadius:BorderRadius.circular(26)),child:Row(children:[Container(width:58,height:58,decoration:BoxDecoration(color:_purple,borderRadius:BorderRadius.circular(18)),child:const Icon(Icons.play_arrow_rounded,color:Colors.white,size:32)),const SizedBox(width:15),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Your next session',style:TextStyle(color:Colors.white54,fontSize:12,fontWeight:FontWeight.w700)),SizedBox(height:4),Text('Start with squat form',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w900)),SizedBox(height:4),Text('8 min • form focus',style:TextStyle(color:Colors.white54,fontSize:12))])),IconButton(onPressed:onStart,tooltip:'Start squat check',icon:const Icon(Icons.arrow_forward_rounded,color:Colors.white))])); }
class _ProfilePage extends StatelessWidget { const _ProfilePage(); @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(20,20,20,28),children:[const Text('Profile',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:_ink)),const SizedBox(height:6),const Text('Your training space.',style:TextStyle(color:_muted,fontSize:14)),const SizedBox(height:24),Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[_purpleDark,Color(0xFF8B79FF)]),borderRadius:BorderRadius.circular(26)),child:Row(children:[Container(width:58,height:58,decoration:BoxDecoration(color:Colors.white24,shape:BoxShape.circle),child:const Icon(Icons.person_rounded,color:Colors.white,size:32)),const SizedBox(width:15),const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Welcome to Pose',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w900)),SizedBox(height:4),Text('Train with better form',style:TextStyle(color:Colors.white70))])])),const SizedBox(height:18),const _ProfileRow(icon:Icons.flag_outlined,title:'Training goal',value:'Build better movement'),const _ProfileRow(icon:Icons.accessibility_new_rounded,title:'Focus',value:'Form & technique'),const _ProfileRow(icon:Icons.shield_outlined,title:'Privacy',value:'On-device first'),const SizedBox(height:18),Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xFFEDEAF2))),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.lock_outline_rounded,color:_purple),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Private by design',style:TextStyle(color:_ink,fontWeight:FontWeight.w800)),SizedBox(height:4),Text('Pose is designed to keep core movement analysis on your device.',style:TextStyle(color:_muted,height:1.4,fontSize:13))]))]))]); }
class _ProfileRow extends StatelessWidget { const _ProfileRow({required this.icon,required this.title,required this.value}); final IconData icon; final String title,value; @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:_surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFEDEAF2))),child:Row(children:[Icon(icon,color:_purple),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:12,color:_muted)),const SizedBox(height:3),Text(value,style:const TextStyle(fontWeight:FontWeight.w800,color:_ink))])),const Icon(Icons.chevron_right_rounded,color:_muted)])); }
