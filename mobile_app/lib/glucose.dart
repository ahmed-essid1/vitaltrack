import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:connectedwatch/services/api.dart';

class GlucoseScreen extends StatefulWidget {
  @override
  _GlucoseScreenState createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? glucose;
  String? errorMessage;

  late AnimationController _animationController;
  late Animation<double> _animation;

  // Dynamic form values
  int hypertension = 0;
  int heart_disease = 0;
  int diabetes = 0;
  int gender = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(_animationController);

    fetchGlucose();
  }

  Future<void> fetchGlucose() async {
    try {
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
        throw Exception("Invalid date format");
      }

      // Get gender value: 1 for male, 0 for female
      gender = userDoc['gender'] == 'Male' ? 1 : 0;

      int age = calculateAge(dateOfBirth);
      double bmi = calculateBmi(weight, height);

      // Features list
      List<double> features = [
        gender.toDouble(),
        age.toDouble(),
        hypertension.toDouble(),
        heart_disease.toDouble(),
        diabetes.toDouble(),
        bmi,
      ];

      print("📊 Features: $features");

      String? result = await ApiService.getGlucose(features);
      print("✅ API Response: $result");

      if (result == null || result.isEmpty) {
        throw Exception("Received empty or null response from API");
      }

      setState(() {
        isLoading = false;
        glucose = result; // Set glucose to the result from the API
        errorMessage = null;
        _animationController.stop();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        glucose = null;
        errorMessage = "Erreur lors de la récupération: $e"; // Include error details for debugging
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

  double calculateBmi(double weight, double height) {
    if (height == 0) return 0.0; // Avoid division by zero
    // Height should be in meters for BMI formula
    height = height / 100; // Assuming height is in cm
    double bmi = weight / (height * height);
    return bmi;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade200, // Fond violet clair
      body: Stack(
        children: [
          // Icônes semi-transparentes repositionnées
          Positioned(top: 80, left: 40, child: _backgroundIcon(Icons.water_drop, 80)),
          Positioned(top: 100, right: 40, child: _backgroundIcon(Icons.medical_services, 90)),
          Positioned(bottom: 150, left: 30, child: _backgroundIcon(Icons.water_drop, 70)),
          Positioned(bottom: 80, right: 50, child: _backgroundIcon(Icons.health_and_safety, 100)),

          // Bouton retour en haut à gauche
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.purple.shade700, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Animation au centre
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  Text("Health Parameters", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                  SizedBox(height: 20),

                  // Heart disease
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Do you have heart disease?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Switch(
                        value: heart_disease == 1,
                        onChanged: (val) {
                          setState(() {
                            heart_disease = val ? 1 : 0;
                          });
                        },
                      ),
                    ],
                  ),

                  // Hypertension
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Are you diagnosed with hypertension?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Switch(
                        value: hypertension == 1,
                        onChanged: (val) {
                          setState(() {
                            hypertension = val ? 1 : 0;
                          });
                        },
                      ),
                    ],
                  ),

                  // Diabetes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Are you diagnosed with diabetes?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Switch(
                        value: diabetes == 1,
                        onChanged: (val) {
                          setState(() {
                            diabetes = val ? 1 : 0;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        glucose = null;
                        errorMessage = null;
                      });
                      fetchGlucose();
                    },
                    icon: Icon(Icons.water_drop),
                    label: Text("Measure Glucose Level"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    ),
                  ),
                  SizedBox(height: 30),
                  if (isLoading) ...[
                    ScaleTransition(
                      scale: _animation,
                      child: Icon(Icons.water_drop, color: Colors.purple.shade700, size: 80),
                    ),
                    SizedBox(height: 20),
                    CircularProgressIndicator(color: Colors.purple.shade700),
                    SizedBox(height: 10),
                  ] else if (glucose != null) ...[
                    Icon(Icons.water_drop, color: Colors.purple.shade700, size: 80),
                    SizedBox(height: 20),
                    Text(
                      "Glucose Level: $glucose",
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                    ),
                  ] else if (errorMessage != null) ...[
                    SizedBox(height: 20),
                    Text(
                      errorMessage!,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to generate background icons
  Widget _backgroundIcon(IconData icon, double size) {
    return Opacity(
      opacity: 0.2, // Semi-transparent icons
      child: Icon(icon, color: Colors.purple.shade700, size: size),
    );
  }
}
