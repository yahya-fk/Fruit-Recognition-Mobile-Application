import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text(
          "HOME",
          style: TextStyle(color: Colors.white,fontSize: 20),
        ), 
      centerTitle: true,
      backgroundColor: Colors.amberAccent,),
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
                    backgroundImage: AssetImage("images/avatar.jpg"),
                  ),
                ),
                  Text("Yahya FEKRANE",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                 Text(
                  "yahya.fekrane@emsi-edu.ma",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                ]
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Covid Tracker'),
              onTap: (){
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
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
      body: Center(
        child: Text(
        textAlign: TextAlign.center,
        "Welcome to the App",
        style: TextStyle(color: Colors.blueGrey,fontSize: 30),
        ),        
      )
    );
  }
}