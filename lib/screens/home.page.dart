import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:controllapp/services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = '';
  String userEmail = '';
  String userPhotoUrl = '';
  String userImageBase64 = '';

  @override
  void initState() {
    super.initState();
    // Check if user is not authenticated
    if (!AuthService.isAuthenticated()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
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
        });
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
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
        title: Text(
          "HOME",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
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
                  Text(
                    userName,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Covid Tracker'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.android),
              title: Text('Emsi Chatbot'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              trailing: Icon(Icons.arrow_forward),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer first
                Navigator.pushReplacementNamed(context, '/settings'); // Use pushReplacement instead of push
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: logout,
            )
          ],
        ),
      ),
      body: Center(
        child: Text(
          textAlign: TextAlign.center,
          "Welcome to the App",
          style: TextStyle(color: Colors.blueGrey, fontSize: 30),
        ),
      ),
    );
  }
}