import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase

class OxygenScreen extends StatefulWidget {
  @override
  _OxygenScreenState createState() => _OxygenScreenState();
}

class _OxygenScreenState extends State<OxygenScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? oxygenLevel;
  late AnimationController _controller;
  late Animation<double> _animation;
  final DatabaseReference _realtimeDB = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    // Animation for simulating a slight movement of the oxygen icon
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(_controller);

    // Fetch the oxygen level from Firebase after 3 seconds
    Timer(Duration(seconds: 3), () {
      fetchOxygenLevel(); // Fetch oxygen level from Firebase
    });
  }

  Future<void> fetchOxygenLevel() async {
    try {
      // Fetch oxygen level from Firebase Realtime Database
      DatabaseEvent event = await _realtimeDB.child("health_data").once();
      Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null || data['spo2'] == null) {
        throw Exception("No oxygen level data found");
      }

      // Update state with oxygen level value
      setState(() {
        isLoading = false;
        oxygenLevel = data['spo2'].toString();
        _controller.stop(); // Stop animation after fetching data
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        oxygenLevel = "Error fetching data"; // Display error if data fetch fails
        _controller.stop();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade200, // Light background
      body: Stack(
        children: [
          // Add semi-transparent background icons
          Positioned(top: 80, left: 40, child: _backgroundIcon(Icons.local_hospital, 80)),
          Positioned(top: 100, right: 40, child: _backgroundIcon(Icons.water_drop, 90)),
          Positioned(bottom: 150, left: 30, child: _backgroundIcon(Icons.bloodtype, 100)),
          Positioned(bottom: 80, right: 50, child: _backgroundIcon(Icons.monitor_heart, 70)),

          // Back button at the top-left
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.blue.shade900, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Main content at the center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  ScaleTransition(
                    scale: _animation,
                    child: Image.asset(
                      'lib/assets/saturation.png', // Make sure the image exists
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Measuring Oxygen Level...",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                  SizedBox(height: 10),
                  CircularProgressIndicator(color: Colors.blue),
                ] else ...[
                  // Display Oxygen Level after loading
                  Image.asset('lib/assets/saturation.png', width: 100, height: 100),
                  SizedBox(height: 20),
                  Text(
                    oxygenLevel != null
                        ? "Oxygen Level: $oxygenLevel%"
                        : "Failed to fetch oxygen level",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to generate semi-transparent background icons
  Widget _backgroundIcon(IconData icon, double size) {
    return Opacity(
      opacity: 0.2, // Semi-transparent icons
      child: Icon(icon, color: Colors.blue.shade900, size: size),
    );
  }
}
