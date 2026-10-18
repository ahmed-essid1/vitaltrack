import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:connectedwatch/services/api.dart';

class StabilityScreen extends StatefulWidget {
  @override
  _StabilityScreenState createState() => _StabilityScreenState();
}

class _StabilityScreenState extends State<StabilityScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? stability;
  String? heartRateStatus;
  String? spo2Status;
  String? errorMessage;
  late AnimationController _controller;
  late Animation<double> _animation;

  final DatabaseReference _realtimeDB = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(_controller);

    fetchStability();
  }

  Future<void> fetchStability() async {
    try {
      DatabaseEvent event = await _realtimeDB.child("health_data").once();
      Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;

      print(" Fetched Data from Firebase Realtime DB: $data");

      if (data == null) throw Exception("No health data found");

      double heartRate = (data['heart_rate'] ?? 0).toDouble();
      double spo2 = (data['spo2'] ?? 0).toDouble();

      print("❤️ Heart Rate: $heartRate, O₂ Saturation: $spo2");

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (!userDoc.exists) throw Exception("User data not found");

      dynamic dobData = userDoc['date_of_birth'];
      DateTime dateOfBirth;

      if (dobData is Timestamp) {
        dateOfBirth = dobData.toDate();
      } else if (dobData is String) {
        try {
          dateOfBirth = DateFormat("dd/MM/yyyy").parse(dobData);
        } catch (e) {
          throw Exception("Invalid date format in Firestore: $e");
        }
      } else {
        throw Exception("Invalid date format in Firestore");
      }

      int age = _calculateAge(dateOfBirth);
      print("🎂 User Age: $age");

      List<double> features = [age.toDouble(), heartRate, spo2];
      print("📊 Features Sent to API: $features");

      String? stabilityResult = await ApiService.getStability(features);
      print("✅ API Response: $stabilityResult");

      setState(() {
        isLoading = false;
        stability = stabilityResult ?? "No stability data";
        heartRateStatus = _getHeartRateStatus(age,heartRate);
        spo2Status = _getSpo2Status(age,spo2);
        errorMessage = null;
        _controller.stop();
      });
    } catch (error) {
      print("❌ Error: $error");
      setState(() {
        isLoading = false;
        stability = null;
        errorMessage = "Failed to fetch stability";
        _controller.stop();
      });
    }
  }

  int _calculateAge(DateTime dateOfBirth) {
    final currentDate = DateTime.now();
    int age = currentDate.year - dateOfBirth.year;
    if (currentDate.month < dateOfBirth.month || (currentDate.month == dateOfBirth.month && currentDate.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  String _getHeartRateStatus(int age, double heartRate) {
    if (age <= 2 && 100 <= heartRate && heartRate <= 160) {
      return "Heart rate stable";
    } else if (2 < age && age <= 6 && 70 <= heartRate && heartRate <= 120) {
      return "Heart rate stable";
    } else if (6 < age && age <= 12 && 60 <= heartRate && heartRate <= 110) {
      return "Heart rate stable";
    } else if (12 < age && age <= 18 && 50 <= heartRate && heartRate <= 100) {
      return "Heart rate stable";
    } else if (18 < age && 60 <= heartRate && heartRate <= 100) {
      return "Heart rate stable";
    } else {
      return "Heart rate unstable";
    }
  }

  String _getSpo2Status(int age, double spo2) {
    if (age <= 65 && 95 < spo2 && spo2 < 100) {
      return "Oxygen stable";
    } else if (age > 65 && 94 < spo2 && spo2 < 98) {
      return "Oxygen stable";
    } else if (spo2 >= 95) {
      return "Oxygen stable";
    } else if (spo2 <= 94) {
      return "Oxygen unstable";
    } else {
      return "Oxygen unstable";
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
      backgroundColor: Colors.yellow.shade300,
      body: Stack(
        children: [
          Positioned(top: 80, left: 50, child: _backgroundIcon(Icons.accessibility_new, 80)),
          Positioned(top: 100, right: 40, child: _backgroundIcon(Icons.directions_walk, 90)),
          Positioned(bottom: 150, left: 30, child: _backgroundIcon(Icons.balance, 100)),
          Positioned(bottom: 80, right: 50, child: _backgroundIcon(Icons.sports_gymnastics, 70)),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.yellow.shade900, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  ScaleTransition(
                    scale: _animation,
                    child: Icon(Icons.stacked_line_chart, color: Colors.yellow.shade900, size: 80),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Measuring Stability...",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.yellow.shade900),
                  ),
                  SizedBox(height: 10),
                  CircularProgressIndicator(color: Colors.yellow.shade900),
                ] else ...[
                  Icon(Icons.stacked_line_chart, color: Colors.yellow.shade900, size: 80),
                  SizedBox(height: 20),
                  Text(
                    stability ?? errorMessage ?? "No data available",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.yellow.shade900),
                  ),
                  SizedBox(height: 20),
                  if (heartRateStatus != null && spo2Status != null) ...[
                    Text("❤️ Heart Rate: $heartRateStatus", style: TextStyle(fontSize: 20, color: Colors.orange.shade500, fontWeight: FontWeight.bold)),
                    Text("🫁 Oxygen: $spo2Status", style: TextStyle(fontSize: 20, color: Colors.orange.shade500, fontWeight: FontWeight.bold)),
                  ]
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundIcon(IconData icon, double size) {
    return Opacity(
      opacity: 0.2,
      child: Icon(icon, color: Colors.yellow.shade900, size: size),
    );
  }
}
