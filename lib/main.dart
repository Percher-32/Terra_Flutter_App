import 'package:flutter/material.dart';
import 'package:nextfind/pages/searchpage.dart';
// import 'package:nextfind/pages/searchpage.dart';
import 'pages/homepage.dart';
import 'package:nextfind/utils/arbitStore.dart';

void main() {
  Arbitfallbacks();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Next Find',
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      // home: const MyHomePage(title: 'Next Find'),
      home : const SearchPage(),
    );
  }
}


//$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"



//gradle --stop; `
//taskkill /F /IM gradle.exe /T; `
//taskkill /F /IM java.exe /T; `
//taskkill /F /IM javaw.exe /T; `
//taskkill /F /IM dart.exe /T; `
//taskkill /F /IM flutter.exe /T; `
//taskkill /F /IM adb.exe /T; `
//taskkill /F /IM studio64.exe /T; `
//taskkill /F /IM fsnotifier.exe /T

//Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle"
//Remove-Item -Recurse -Force "C:\Users\User\Desktop\CODE\Flutter_Service_App\nextfind\android\.gradle"

//flutter clean
//flutter pub get
//flutter run





//[] ([he] [is] [the]) ([for][ty][forth]) ([pre][sid][dent]) ([of] [the]) ([U][NIT][ED] [STATES])
// ([ev][ery][bo][dy]) ([give][it][up][for]) ([the][one][and][only]) ([BARACK][HUSIEN])
// OBAMA ,