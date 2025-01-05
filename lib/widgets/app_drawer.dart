import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = '';
  String userEmail = '';
  String userImageBase64 = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        setState(() {
          userName = userData['fullName'] ?? '';
          userEmail = userData['email'] ?? '';
          userImageBase64 = userData['profileImage'] ?? '';
        });
      }
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

  Future<void> logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: screenSize.height * 0.08,
                  width: screenSize.height * 0.08,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundImage: getProfileImage(),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: screenSize.width * 0.035,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: Icon(Icons.camera),
            title: Text('Classifier'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/model');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            trailing: Icon(Icons.arrow_forward),
            title: Text('Settings'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: logout,
          )
        ],
      ),
    );
  }
}
