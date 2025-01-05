import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

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
  String? _base64Image;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isImageSelected = false;

  // Default profile picture URL
  final String defaultPhotoURL =
      "https://i.pinimg.com/736x/c0/74/9b/c0749b7cc401421662ae901ec8f9f660.jpg";

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Limit image size
        maxHeight: 800,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _base64Image = base64Encode(bytes);
          isImageSelected = true;
        });
      } else {
        Fluttertoast.showToast(msg: "No image selected.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error picking image: $e");
    }
  }

  Future<void> signUp() async {
    if (!isImageSelected) {
      Fluttertoast.showToast(msg: "Please select a profile picture");
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        String? photoData = _base64Image ?? '';

        // Update user profile with display name
        await user.updateDisplayName(_nameController.text.trim());

        // Save user information to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'profileImage': photoData, // Store base64 string
          'createdAt': FieldValue.serverTimestamp(),
        });

        Fluttertoast.showToast(
          msg: "Registration successful!",
          toastLength: Toast.LENGTH_SHORT,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
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
    final Size screenSize = MediaQuery.of(context).size;
    final double safeAreaPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "REGISTER",
          style: TextStyle(
            color: Colors.white,
            fontSize: screenSize.width * 0.06,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber.shade400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: screenSize.width,
          height: screenSize.height - safeAreaPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.amber.shade100, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenSize.width * 0.05),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    height: screenSize.width * 0.3,
                                    width: screenSize.width * 0.3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.amber.shade400,
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: screenSize.width * 0.15,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage: _pickedImage != null
                                          ? FileImage(File(_pickedImage!.path))
                                          : null,
                                      child: _pickedImage == null
                                          ? Icon(Icons.person,
                                              size: screenSize.width * 0.15,
                                              color: Colors.grey)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(screenSize.width * 0.02),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.camera_alt,
                                          size: screenSize.width * 0.05,
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isImageSelected)
                              Padding(
                                padding: EdgeInsets.only(top: screenSize.height * 0.01),
                                child: Text(
                                  'Profile picture is required',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: screenSize.width * 0.035,
                                  ),
                                ),
                              ),
                            SizedBox(height: screenSize.height * 0.02),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person, color: Colors.amber.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.amber.shade400,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email, color: Colors.amber.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.amber.shade400,
                                    width: 2,
                                  ),
                                ),
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
                            SizedBox(height: screenSize.height * 0.02),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_passwordVisibility,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock, color: Colors.amber.shade400),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _passwordVisibility = !_passwordVisibility),
                                  icon: Icon(
                                    _passwordVisibility ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.amber.shade400,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.amber.shade400,
                                    width: 2,
                                  ),
                                ),
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
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() && isImageSelected) {
                          signUp();
                        } else if (!isImageSelected) {
                          Fluttertoast.showToast(msg: "Please select a profile picture");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade400,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.15,
                          vertical: screenSize.width * 0.04,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, "/login"),
                      child: Text(
                        'Already have an account? Log in',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: screenSize.width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
