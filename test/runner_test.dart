// import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/utils/businessManager.dart';

Future<void> main() async {
  print("STARTING TEST");

  final result = await businessManager.getBusinessData([2, 3, 4, 5]);
  final result2 = await businessManager.getBusinessData([4, 5]);

  print("RESULT:");
  print(result);
  
  print("RESULT2:");
  print(result2);
}



//flutter test test/runner_test.dart