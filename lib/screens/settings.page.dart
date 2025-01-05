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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.amberAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber),
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircleAvatar(
                      backgroundImage: getProfileImage(),
                    ),
                  ),
                  Text(userName, style: TextStyle(color: Colors.white, fontSize: 20)),
                  Text(userEmail, style: TextStyle(color: Colors.white, fontSize: 15)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Covid Tracker'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.android),
              title: Text('Emsi Chatbot'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              trailing: Icon(Icons.arrow_forward),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Just close drawer since we're already on settings
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: getProfileImage(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  updateUserProfile();
                  if (_currentPasswordController.text.isNotEmpty &&
                      _newPasswordController.text.isNotEmpty) {
                    updatePassword();
                  }
                },
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
