import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisibility = false;
  Future<void> SignIn() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        print("Signed in: ${userCredential.user?.email}");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Sign-in successful")));
        // Naviguer vers la page d'accueil (Home) après une connexion réussie
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No user found for that email.";
          break;
        case 'wrong-password':
          message = "Wrong password provided.";
          break;
        case 'invalid-email':
          message = "The email address is invalid.";
          break;
        case 'user-disabled':
          message = "This user account has been disabled.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later.";
          break;
        default:
          message = "An error occurred. Try again.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      print("FirebaseAuthException: $message");
    } on SocketException catch (e) {
      // Bloc spécifique pour les problèmes de réseau
      String message = "Network error: Please check your internet connection.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      print("SocketException: $e");
    } catch (e) {
      // Bloc général pour les autres erreurs
      String message = "An unexpected error occurred.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      print("Unknown error: $e");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'images/application.jpg', // Replace with your image path
                  width: double.infinity,
                  height: 220.0,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisibility,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _passwordVisibility = !_passwordVisibility;
                      });
                    },
                    icon: Icon(
                      _passwordVisibility
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  } else if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    SignIn(); // Call the SignIn method when the form is valid
                  }
                },
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),

              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to registration')),
                  );
                  Navigator.pushNamed(context, "/register");
                },
                child: const Text('Create a new account',
                style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
