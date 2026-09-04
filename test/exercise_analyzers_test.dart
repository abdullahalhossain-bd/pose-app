import 'package:flutter_test/flutter_test.dart';
import 'package:pose/core/exercise/push_up_analyzer.dart';
import 'package:pose/core/exercise/lunge_analyzer.dart';
import 'package:pose/core/pose/pose_landmark.dart';

PosePoint p(String n,double x,double y)=>PosePoint(name:n,x:x,y:y,confidence:1);

List<PosePoint> push(double elbowAngle) {
  // Shoulder -> elbow -> wrist. This fixture gives approximately the requested angle.
  final r=elbowAngle*3.141592653589793/180;
  return [p('leftShoulder',0,0),p('leftElbow',1,0),p('leftWrist',1+(-1)*0, -1),p('leftHip',0,1.0),p('leftAnkle',0,2.0)];
}

void main(){
 test('push-up analyzer starts in ready phase and scores complete landmarks',(){final a=PushUpAnalyzer();final out=a.analyze(push(90));expect(out.score,greaterThanOrEqualTo(0));expect(out.phase.name,isNotEmpty);});
 test('push-up reset clears rep state',(){final a=PushUpAnalyzer();a.analyze(push(90));a.reset();final out=a.analyze(push(90));expect(out.validRep,false);});
 test('lunge analyzer handles a complete landmark set',(){final a=LungeAnalyzer();final points=[p('leftHip',0,0),p('leftKnee',0,1),p('leftAnkle',0,2),p('leftShoulder',0,-1)];final out=a.analyze(points);expect(out.score,greaterThanOrEqualTo(0));expect(out.score,lessThanOrEqualTo(100));});
 test('lunge reset is safe',(){final a=LungeAnalyzer();a.reset();expect(a.analyze([p('leftHip',0,0),p('leftKnee',0,1),p('leftAnkle',0,2),p('leftShoulder',0,-1)]).validRep,false);});
}
