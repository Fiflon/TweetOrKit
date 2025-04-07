import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tweetorkit/core/themes/main_theme.dart';
import 'package:tweetorkit/features/auth/controllers/user_controller.dart';
import 'package:tweetorkit/features/auth/widgets/password_field.dart';
import 'package:tweetorkit/features/auth/widgets/submit_button.dart';
import 'package:tweetorkit/main_navigation.dart'; // Adjust the path as needed

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enteredEmail = TextEditingController();
  final _enteredUsername = TextEditingController();
  final _enteredPassword1 = TextEditingController();
  final _enteredPassword2 = TextEditingController();

  @override
  void dispose() {
    _enteredEmail.dispose();
    _enteredUsername.dispose();
    _enteredPassword1.dispose();
    _enteredPassword2.dispose();
    super.dispose();
  }

  void submitForm() {
    if (_formKey.currentState!.validate()) {
      // Jeśli formularz jest poprawny, zapisz dane
      _formKey.currentState!.save();

      // Przykładowa logika po przesłaniu formularza
      print('Email: ${_enteredEmail.text}');
      print('Username: ${_enteredUsername.text}');
      print('Password: ${_enteredPassword1.text}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign-in')),
      backgroundColor: MainTheme.mainTheme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    controller: _enteredEmail,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a valid email address.';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email format.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Username"),
                    keyboardType: TextInputType.name,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    controller: _enteredUsername,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a valid username.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _enteredPassword1,
                    labelText: "Password",
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a valid password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _enteredPassword2,
                    labelText: "Repeat password",
                    validator: (value) {
                      if (value != _enteredPassword1.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SubmitButton(onPressed: submitForm),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final user = await UserController.loginWithGoogle();
                        if (user != null && context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const MainNavigation(),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message ?? 'An error occurred'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
