import 'package:controllapp/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  String userName = '';
  String userEmail = '';
  String userImageBase64 = '';
  
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        setState(() {
          userName = userData['fullName'] ?? '';
          userEmail = userData['email'] ?? '';
          userImageBase64 = userData['profileImage'] ?? '';
          _fullNameController.text = userName;
        });
      }
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        userImageBase64 = base64Encode(bytes);
      });
      updateUserProfile(image: userImageBase64);
    }
  }

  Future<void> updateUserProfile({String? image}) async {
    User? user = _auth.currentUser;
    if (user != null) {
      Map<String, dynamic> updateData = {};
      
      if (_fullNameController.text.isNotEmpty && _fullNameController.text != userName) {
        updateData['fullName'] = _fullNameController.text;
      }
      
      if (image != null) {
        updateData['profileImage'] = image;
      }
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updateData);
        Fluttertoast.showToast(msg: "Profile updated successfully!");
        loadUserData();
      }
    }
  }

  Future<void> updatePassword() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);
        
        Fluttertoast.showToast(msg: "Password updated successfully!");
        _currentPasswordController.clear();
        _newPasswordController.clear();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error updating password: ${e.toString()}");
    }
  }

  ImageProvider getProfileImage() {
    if (userImageBase64.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(userImageBase64));
      } catch (e) {
        return const AssetImage("images/avatar.jpg");
      }
    }
    return const AssetImage("images/avatar.jpg");
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double safeAreaPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "SETTINGS",
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
      drawer: AppDrawer(),
      body: SafeArea(
        child: Container(
          width: screenSize.width,
          height: screenSize.height - safeAreaPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.amber.shade100,
                Colors.white,
              ],
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
                              child: Container(
                                height: screenSize.width * 0.25,
                                width: screenSize.width * 0.25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.amber.shade400,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundImage: getProfileImage(),
                                ),
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Text(
                              'Profile Settings',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
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
                                prefixIcon: Icon(Icons.person, color: Colors.amber.shade400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenSize.width * 0.05),
                        child: Column(
                          children: [
                            Text(
                              'Security',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            TextFormField(
                              controller: _currentPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.lock, color: Colors.amber.shade400),
                              ),
                              obscureText: true,
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            TextFormField(
                              controller: _newPasswordController,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.amber.shade400),
                              ),
                              obscureText: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    ElevatedButton(
                      onPressed: () {
                        updateUserProfile();
                        if (_currentPasswordController.text.isNotEmpty &&
                            _newPasswordController.text.isNotEmpty) {
                          updatePassword();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade400,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.08,
                          vertical: screenSize.width * 0.04,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.045,
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
