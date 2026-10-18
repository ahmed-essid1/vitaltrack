import 'package:flutter/material.dart';
import 'package:connectedwatch/splash_screen.dart';  // Ensure correct import
import 'package:connectedwatch/welcome_screen.dart';
import 'package:connectedwatch/login.dart';
import 'package:connectedwatch/signup.dart';
import 'package:connectedwatch/set_password.dart';
import 'package:connectedwatch/home.dart';
import 'package:connectedwatch/heart_rate.dart';
import 'package:connectedwatch/glucose.dart';
import 'package:connectedwatch/physical_activity.dart';
import 'package:connectedwatch/blood_pressure.dart';
import 'package:connectedwatch/oxygen.dart';
import 'package:connectedwatch/stability.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(VitalTrackApp());
}

class VitalTrackApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitalTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/splash',  // Show SplashScreen first
      routes: {
        '/splash': (context) => SplashScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup':(context) => SignUpScreen(),
        '/set_password':(context)=> SetPasswordScreen(),
        '/home':(context)=> HomeScreen(),
        '/heart_rate':(context)=> HeartRateScreen(),
        '/glucose':(context)=> GlucoseScreen(),
        '/physical_activity':(context)=> PhysicalActivityScreen(),
        '/blood_pressure':(context)=> BloodPressureScreen(),
        '/oxygen':(context)=> OxygenScreen(),
        '/stability':(context)=> StabilityScreen(),


      },
    );
  }
}
