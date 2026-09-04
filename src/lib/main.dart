import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:my_mtr_schedule/data/localized_string.dart';
import 'package:my_mtr_schedule/screen/home_screen.dart';
import 'package:my_mtr_schedule/screen/wear_home_screen.dart';
import 'package:my_mtr_schedule/service/preferences_service.dart';

void main() async {
  // Required when doing async operations before runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isWatch = false;

  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    isWatch = androidInfo.systemFeatures.contains('android.hardware.type.watch');
  }

  runApp(MyApp(isWatch: isWatch));
}

class MyApp extends StatefulWidget {
  final bool isWatch;

  const MyApp({super.key, required this.isWatch});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLang _lang = AppLang.en;

  @override
  void initState() {
    super.initState();
    
    _loadLang();
  }

  void _loadLang() async {
    final savedLang = await PreferencesService.loadLanguage();
    setState(() {
      _lang = savedLang;
    });
  }

  void _toggleLang() {
    setState(() {
      _lang = _lang == AppLang.en ? AppLang.tc : AppLang.en;
    });
    PreferencesService.saveLanguage(_lang);
  }

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   title: "MTR Schedule",
    //   debugShowCheckedModeBanner: false,
    //   theme: ThemeData(
    //     primarySwatch: Colors.blue,
    //     useMaterial3: true,
    //     // fontFamily: _lang == AppLang.tc ? "Noto Sans HK" : "Roboto", 
    //     fontFamily: "Noto Sans HK", 
    //   ),
    //   home: HomeScreen(lang: _lang, onLangToggle: _toggleLang),
    // );
    return MaterialApp(
      title: "MTR Schedule",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: lightPurpleColor,
        scaffoldBackgroundColor: widget.isWatch ? Colors.black : const Color(0xFF121212),
        useMaterial3: true,
          // fontFamily: _lang == AppLang.tc ? "Noto Sans HK" : "Roboto", 
          fontFamily: "Noto Sans HK", 
        
        // SET GLOBAL TEXT COLOR TO LIGHT PURPLE
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: lightPurpleColor),
          bodyMedium: TextStyle(color: lightPurpleColor),
          titleLarge: TextStyle(color: lightPurpleColor, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: lightPurpleColor),
        ),
        
        // Update Input/Dropdown Styles
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: lightPurpleColor),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.purple[100]!.withValues(alpha: 0.5)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: lightPurpleColor),
          ),
        ),
      ),
      home: widget.isWatch ? WearHomeScreen(lang: _lang, onLangToggle: _toggleLang) : HomeScreen(lang: _lang, onLangToggle: _toggleLang),
    );
  }
}

