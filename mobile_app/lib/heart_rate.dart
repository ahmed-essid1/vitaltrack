import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:connectedwatch/services/api.dart';

class HeartRateScreen extends StatefulWidget {
  @override
  _HeartRateScreenState createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? heartRate;
  String? currentHeartRate;
  String? errorMessage;

  late AnimationController _animationController;
  late Animation<double> _animation;

  final _realtimeDB = FirebaseDatabase.instance.ref();
  int FastingBS = 0;
  int ExerciseAngina = 0;
  int HeartDisease = 0;
  int gender = 0;
  int RestingECG = 0;
  double restingBP = 0.0;  // Variable to hold resting blood pressure

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(_animationController);

    fetchHeartRate();
  }

  Future<void> fetchHeartRate() async {
    try {
      DatabaseEvent event = await _realtimeDB.child("health_data").once();
      Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) throw Exception("No health data found");

      currentHeartRate = data['heart_rate']?.toString() ?? 'No current heart rate data';

      RestingECG = data['RestingECG'] ?? 0;
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      // Fetching resting BP value from Firebase
      DatabaseEvent bpEvent = await _realtimeDB.child("users/$userId/restingBP/value").once();
      if (bpEvent.snapshot.value != null) {
        final value = bpEvent.snapshot.value;
        if (value is String) {
          restingBP = double.tryParse(value) ?? 0.0;
        } else if (value is num) {
          restingBP = value.toDouble();
        } else {
          restingBP = 0.0;
        }
      } else {
        restingBP = 0.0;
      }

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

      gender = userDoc['gender'] == 'Male' ? 1 : 0;
      int age = calculateAge(dateOfBirth);

      // Add restingBP to features
      List<double> features = [
        age.toDouble(),
        gender.toDouble(),
        restingBP,  // Add restingBP to the features list
        FastingBS.toDouble(),
        RestingECG.toDouble(),
        ExerciseAngina.toDouble(),
        HeartDisease.toDouble(),
      ];

      print("📊 Features: $features");

      String? result = await ApiService.getHeartRate(features);
      print("✅ API Response: $result");

      if (result == null || result.isEmpty) throw Exception("Received empty or null response from API");

      setState(() {
        isLoading = false;
        heartRate = result;
        errorMessage = null;
        _animationController.stop();
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        heartRate = null;
        errorMessage = "Erreur lors de la récupération: $e";
        _animationController.stop();
      });
    }
  }

  int calculateAge(DateTime dateOfBirth) {
    final currentDate = DateTime.now();
    int age = currentDate.year - dateOfBirth.year;
    if (currentDate.month < dateOfBirth.month ||
        (currentDate.month == dateOfBirth.month && currentDate.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade200,
      body: Stack(
        children: [
          Positioned(top: 80, left: 50, child: _backgroundIcon(Icons.favorite_border, 80)),
          Positioned(top: 100, right: 40, child: _backgroundIcon(Icons.monitor_heart, 90)),
          Positioned(bottom: 150, left: 30, child: _backgroundIcon(Icons.health_and_safety, 100)),
          Positioned(bottom: 80, right: 50, child: _backgroundIcon(Icons.favorite, 70)),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.red.shade900, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Text("Health Parameters", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Is your fasting blood sugar >120 mg/dL?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Switch(
                        value: FastingBS == 1,
                        onChanged: (val) => setState(() => FastingBS = val ? 1 : 0),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Do you have heart disease?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Switch(
                        value: HeartDisease == 1,
                        onChanged: (val) => setState(() => HeartDisease = val ? 1 : 0),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Do you have exercise-induced angina?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Switch(
                        value: ExerciseAngina == 1,
                        onChanged: (val) => setState(() => ExerciseAngina = val ? 1 : 0),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        heartRate = null;
                        currentHeartRate = null;
                        errorMessage = null;
                      });
                      fetchHeartRate();
                    },
                    icon: Icon(Icons.favorite),
                    label: Text("Measure Heart Rate"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    ),
                  ),
                  SizedBox(height: 30),
                  if (isLoading) ...[
                    ScaleTransition(
                      scale: _animation,
                      child: Icon(Icons.favorite, color: Colors.red.shade900, size: 80),
                    ),
                    SizedBox(height: 20),
                    Text("Measuring Heart Rate...", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                    SizedBox(height: 10),
                    CircularProgressIndicator(color: Colors.red.shade900),
                  ] else ...[
                    Icon(Icons.favorite, color: Colors.red.shade900, size: 80),
                    SizedBox(height: 20),
                    if (currentHeartRate != null || heartRate != null) ...[
                      if (currentHeartRate != null)
                        Text(
                          "Current HR: $currentHeartRate bpm",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                        ),
                      SizedBox(height: 10),
                      if (heartRate != null)
                        Text(
                          "Predicted Max HR: $heartRate",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                    ] else
                      Text(
                        errorMessage ?? "No data available",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundIcon(IconData icon, double size) {
    return Opacity(
      opacity: 0.2,
      child: Icon(icon, color: Colors.red.shade900, size: size),
    );
  }
}
