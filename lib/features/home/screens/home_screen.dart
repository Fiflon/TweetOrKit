import 'package:flutter/material.dart';
import 'package:tweetorkit/features/auth/controllers/user_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          const Center(child: Text('Welcome to TweetOrKit!')),
          CircleAvatar(
            foregroundImage: NetworkImage(
              UserController.currentUser()?.photoURL ?? '',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                UserController.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}
