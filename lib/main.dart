import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tweetorkit/core/database/fetch_creators.dart';
import 'package:tweetorkit/core/themes/main_theme.dart';
import 'package:tweetorkit/features/auth/screens/auth_screen.dart';
import 'package:tweetorkit/features/game/screens/game_screen.dart';
import 'package:tweetorkit/features/home/screens/home_screen.dart';
import 'package:tweetorkit/main_navigation.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await fetchAndStoreUsernames();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TweetOrKit',
      theme: MainTheme.mainTheme, // Główny motyw aplikacji
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Jeśli trwa ładowanie stanu logowania
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Jeśli użytkownik jest zalogowany, przejdź do HomeScreen
          if (snapshot.hasData) {
            // return const HomeScreen();
            // return GameScreen();
            return const MainNavigation();
          }

          // Jeśli użytkownik nie jest zalogowany, przejdź do AuthScreen
          return const AuthScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(), // Ekran główny
        '/game': (context) => const GameScreen(),
        //'/': (context) => const AuthScreen(), // Ekran logowania
      },
    );
  }
}
