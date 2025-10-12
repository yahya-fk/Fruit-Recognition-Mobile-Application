import 'package:controllapp/firebase_options.dart';
import 'package:controllapp/screens/home.page.dart';
import 'package:controllapp/screens/image_classification_screen.dart';
import 'package:controllapp/screens/login.page.dart';
import 'package:controllapp/screens/real_time_classification.page.dart';
import 'package:controllapp/screens/register.page.dart';
import 'package:controllapp/screens/settings.page.dart'; // Add this import
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
          useMaterial3: true,
        ),
        title: 'Yahya APP',
        home: AuthService.isAuthenticated()
            ? const HomePage()
            : const LoginPage(),
        routes: {
          '/login': (context) => AuthService.isAuthenticated()
              ? const HomePage()
              : const LoginPage(),
          '/register': (context) => AuthService.isAuthenticated()
              ? const HomePage()
              : const RegisterPage(),
          '/home': (context) => AuthService.isAuthenticated()
              ? const HomePage()
              : const LoginPage(),
          '/settings': (context) => AuthService.isAuthenticated()
              ? const SettingsPage() // Changed this line
              : const LoginPage(),
          '/model': (context) => AuthService.isAuthenticated()
              ? ImageClassificationScreen()
              : const LoginPage(),
          '/classifier': (context) => AuthService.isAuthenticated()
              ? RealtimeClassificationScreen()
              : const LoginPage(),
        });
  }
}
