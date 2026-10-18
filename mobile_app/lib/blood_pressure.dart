import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:connectedwatch/services/api.dart';

class BloodPressureScreen extends StatefulWidget {
  @override
  _BloodPressureScreenState createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? bloodPressureValue;
  String? bloodPressureCategory;
  String? errorMessage;

  late AnimationController _animationController;
  late Animation<double> _animation;
  final DatabaseReference _realtimeDB = FirebaseDatabase.instance.ref();

  // Dynamic form values
  double chestPain = 0;
  int fastingBS = 0;
  int exerciseAngina = 0;
  int hypertensivePatient = 0;  // New dynamic value for hypertensivePatient
  int restecg = 0;  // Resting ECG value from Firebase
  int gender = 0;   // Gender value, 1 for male, 0 for female

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(_animationController);

    fetchBloodPressure();
  }

  Future<void> fetchBloodPressure() async {
    try {
      DatabaseEvent event = await _realtimeDB.child("health_data").once();
      Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) throw Exception("No health data found");

      double heartRate = (data['heart_rate'] ?? 0).toDouble();
      restecg = data['restecg'] ?? 0;  // Fetch restecg from Firebase

      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception("User data not found");

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

      // Features list
      List<double> features = [
        age.toDouble(),
        gender.toDouble(),
        chestPain,
        fastingBS.toDouble(),
        exerciseAngina.toDouble(),
        heartRate,
        restecg.toDouble(),
        hypertensivePatient.toDouble()
      ];

      print("📊 Features: $features");

      final result = await ApiService.getBloodPressure(features);

      setState(() {
        isLoading = false;
        bloodPressureValue = result?["value"]?.toString();
        bloodPressureCategory = result?["category"]?.toString();
        errorMessage = null;
        _animationController.stop();
      });
      // Store resting BP in Firebase Realtime Database under the user's node
      await _realtimeDB.child("users/$userId/restingBP").set({
        "value": result?["value"],
        "category": result?["category"],
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
    catch (e) {
      setState(() {
        isLoading = false;
        bloodPressureValue = null;
        bloodPressureCategory = null;
        errorMessage = "Erreur lors de la récupération";
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
    return WillPopScope(
      onWillPop: () async {
        print("Back button pressed!");
        Navigator.pop(context); // Handle the back press
        return true; // Allow the system to handle the back action
      },
      child: Scaffold(
        backgroundColor: Colors.orange.shade100,
        body: Stack(
          children: [
            Positioned(top: 80, left: 50, child: _backgroundIcon(Icons.favorite_border, 80)),
            Positioned(top: 100, right: 40, child: _backgroundIcon(Icons.monitor_heart, 90)),
            Positioned(bottom: 150, left: 30, child: _backgroundIcon(Icons.local_hospital, 100)),
            Positioned(bottom: 80, right: 50, child: _backgroundIcon(Icons.favorite, 70)),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.orange.shade900, size: 30),
                onPressed: () {
                  Navigator.pop(context); // This will pop the current screen
                },
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    Text("Health Parameters", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                    SizedBox(height: 20),

                    // Chest Pain
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Do you have chest pain?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Switch(
                          value: chestPain == 1,
                          onChanged: (val) {
                            setState(() {
                              chestPain = val ? 1 : 0;
                            });
                          },
                        ),
                      ],
                    ),

                    // Fasting Blood Sugar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Is your fasting blood sugar >120 mg/dL?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Switch(
                          value: fastingBS == 1,
                          onChanged: (val) => setState(() => fastingBS = val ? 1 : 0),
                        ),
                      ],
                    ),

                    // Angina
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Do you have exercise-induced angina?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Switch(
                          value: exerciseAngina == 1,
                          onChanged: (val) => setState(() => exerciseAngina = val ? 1 : 0),
                        ),
                      ],
                    ),

                    // Hypertensive Patient
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Are you diagnosed with hypertension?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Switch(
                          value: hypertensivePatient == 1,
                          onChanged: (val) => setState(() => hypertensivePatient = val ? 1 : 0),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          bloodPressureValue = null;
                          bloodPressureCategory = null;
                          errorMessage = null;
                        });
                        fetchBloodPressure();
                      },
                      icon: Icon(Icons.bloodtype),
                      label: Text("Measure blood pressure"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      ),
                    ),

                    SizedBox(height: 30),

                    if (isLoading) ...[
                      ScaleTransition(
                        scale: _animation,
                        child: Image.asset('lib/assets/pression.png', width: 100, height: 100),
                      ),
                      SizedBox(height: 20),
                      CircularProgressIndicator(color: Colors.orange.shade900),
                    ] else ...[
                      Image.asset('lib/assets/pression.png', width: 100, height: 100),
                      SizedBox(height: 20),
                      Text(
                        bloodPressureValue != null
                            ? "Pressure: $bloodPressureValue"
                            : errorMessage ?? "Aucune donnée",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                      if (bloodPressureCategory != null)
                        Text("Category: $bloodPressureCategory",
                            style: TextStyle(fontSize: 18, color: Colors.orange.shade800)),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundIcon(IconData icon, double size) {
    return Opacity(
      opacity: 0.2,
      child: Icon(icon, color: Colors.orange.shade900, size: size),
    );
  }
}
