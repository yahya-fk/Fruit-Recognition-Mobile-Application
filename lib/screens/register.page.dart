import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _passwordVisibility = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default profile picture URL
  final String defaultPhotoURL =
      "https://i.pinimg.com/736x/c0/74/9b/c0749b7cc401421662ae901ec8f9f660.jpg";

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      } else {
        Fluttertoast.showToast(msg: "No image selected.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error picking image: $e");
    }
  }

  Future<void> signUp() async {
    try {
      // Create user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        String? photoURL = defaultPhotoURL;

        // Upload the profile picture to Firebase Storage if selected
        if (_pickedImage != null) {
          try {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('profile_pictures/${user.uid}');
            final uploadTask =
                await storageRef.putFile(File(_pickedImage!.path));

            // Ensure the upload task was successful before getting the download URL
            if (uploadTask.state == TaskState.success) {
              photoURL = await storageRef.getDownloadURL();
            } else {
              Fluttertoast.showToast(msg: "Failed to upload profile picture.");
            }
          } catch (e) {
            Fluttertoast.showToast(msg: "Error uploading profile picture: $e");
          }
        }

        // Update user profile with display name and photo URL
        await user.updateDisplayName(_nameController.text.trim());
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        // Save additional user information to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'profilePictureUrl': photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Show success message and navigate
        Fluttertoast.showToast(
          msg: "Registration successful!",
          toastLength: Toast.LENGTH_SHORT,
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        Fluttertoast.showToast(
            msg: "Your password must contain at least 6 characters.");
      } else if (e.code == 'invalid-email') {
        Fluttertoast.showToast(msg: "Invalid email format.");
      } else if (e.code == 'email-already-in-use') {
        Fluttertoast.showToast(msg: "This email is already in use.");
      } else {
        Fluttertoast.showToast(msg: "Error: ${e.message}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "An error occurred: $e");
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : NetworkImage(defaultPhotoURL) as ImageProvider,
                    child: _pickedImage == null
                        ? const Icon(Icons.add_a_photo, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
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
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value)) {
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
                      signUp();
                    }
                  },
                  child: const Text('Register',
                      style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/login");
                  },
                  child: const Text('Already have an account? Log in',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
