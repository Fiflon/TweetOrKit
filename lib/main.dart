import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tweetorkit/core/themes/main_theme.dart';
import 'package:tweetorkit/features/auth/controllers/user_controller.dart';
import 'package:tweetorkit/features/auth/screens/auth_screen.dart';
import 'package:tweetorkit/features/home/screens/home_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TweetOrKit',
      theme: MainTheme.mainTheme, // Główny motyw aplikacji
      initialRoute:
          UserController.currentUser != null ? '/home' : '/', // Domyślna trasa
      routes: {
        '/': (context) => const AuthScreen(), // Ekran logowania
        '/home': (context) => const HomeScreen(), // Ekran główny
      },
    );
  }
}
