import 'package:controllapp/firebase_options.dart';
import 'package:controllapp/screens/home.page.dart';
import 'package:controllapp/screens/login.page.dart';
import 'package:controllapp/screens/register.page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async{
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
      //home: const HomePage(),
      initialRoute: '/login',
      routes: {
        '/login':(context)=> LoginPage(),
        '/register': (context)=>RegisterPage(),
        '/home':(context)=>HomePage(),
        }
    );
  }
}
