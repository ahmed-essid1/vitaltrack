import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:connectedwatch/services/api.dart';

class PhysicalActivityScreen extends StatefulWidget {
  @override
  _PhysicalActivityScreenState createState() => _PhysicalActivityScreenState();
}

class _PhysicalActivityScreenState extends State<PhysicalActivityScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? physicalActivity;
  double? caloriesBurned;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final _realtimeDB = FirebaseDatabase.instance.ref();
  int gender = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(_animationController);

    fetchPhysicalActivity();
  }

  Future<void> fetchPhysicalActivity() async {
    try {
      DatabaseEvent event = await _realtimeDB.child("health_data").once();
      Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) throw Exception("No health data found");

      double accelx = (data['accel_x'] ?? 0).toDouble();
      double accely = (data['accel_y'] ?? 0).toDouble();
      double accelz = (data['accel_z'] ?? 0).toDouble();
      double gyrox = (data['gyro_x'] ?? 0).toDouble();
      double gyroy = (data['gyro_y'] ?? 0).toDouble();
      double gyroz = (data['gyro_z'] ?? 0).toDouble();

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception("User data not found");

      String weightString = userDoc['weight'] ?? "0.0";
      String heightString = userDoc['height'] ?? "0.0";

      double weight = double.tryParse(weightString) ?? 0.0;
      double height = double.tryParse(heightString) ?? 0.0;

      dynamic dobData = userDoc['date_of_birth'];
      DateTime dateOfBirth;

      if (dobData is Timestamp) {
        dateOfBirth = dobData.toDate();
      } else if (dobData is String) {
        dateOfBirth = DateFormat("dd/MM/yyyy").parse(dobData);
      } else {
        throw Exception("Invalid date format in Firestore");
      }

      gender = userDoc['gender'] == 'Male' ? 1 : 0;

      int age = calculateAge(dateOfBirth);
      double time = DateTime.now().second.toDouble();

      List<double> features = [
        gender.toDouble(),
        age.toDouble(),
        time,
        height.toDouble(),
        weight.toDouble(),
        accelx,
        accely,
        accelz,
        gyrox,
        gyroy,
        gyroz,
      ];

      String? result = await ApiService.getPhysicalActivity(features);

      if (result == null || result.isEmpty) {
        throw Exception("Received empty or null response from API");
      }

      double met = getMET(result);
      double durationMinutes = 1.0;
      double calories = (met * weight * 3.5 / 200) * durationMinutes;

      setState(() {
        isLoading = false;
        physicalActivity = result;
        caloriesBurned = calories;
        errorMessage = null;
        _animationController.stop();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        physicalActivity = null;
        caloriesBurned = null;
        errorMessage = "Erreur lors de la récupération: $e";
        _animationController.stop();
      });
    }
  }

  double getMET(String activity) {
    switch (activity.toLowerCase()) {
      case 'sitting':
        return 1.3;
      case 'standing':
        return 1.8;
      case 'walking':
        return 3.5;
      case 'running':
        return 7.0;
      default:
        return 1.5;
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
      backgroundColor: Colors.green.shade200,
      body: Stack(
        children: [
          Positioned(top: 80, left: 40, child: _backgroundIcon(Icons.directions_walk, 80)),
          Positioned(top: 100, right: 40, child: _backgroundIcon(Icons.pedal_bike, 90)),
          Positioned(bottom: 150, left: 30, child: _backgroundIcon(Icons.run_circle, 100)),
          Positioned(bottom: 80, right: 50, child: _backgroundIcon(Icons.hiking, 70)),

          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.green.shade900, size: 30),
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
                    child: Icon(
                      Icons.directions_walk,
                      size: 80,
                      color: Colors.green.shade900,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Tracking Physical Activity...",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                  SizedBox(height: 10),
                  CircularProgressIndicator(color: Colors.green.shade900),
                ] else if (errorMessage != null) ...[
                  Icon(Icons.error, color: Colors.red, size: 80),
                  SizedBox(height: 20),
                  Text(
                    errorMessage!,
                    style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ] else if (physicalActivity != null) ...[
                  Icon(Icons.fitness_center, color: Colors.green.shade900, size: 80),
                  SizedBox(height: 20),
                  Text(
                    "Activity: $physicalActivity",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                  if (caloriesBurned != null) ...[
                    SizedBox(height: 12),
                    Text(
                      "Calories burned: ${caloriesBurned!.toStringAsFixed(2)} kcal",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                  ],
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
      child: Icon(icon, color: Colors.green.shade900, size: size),
    );
  }
}
