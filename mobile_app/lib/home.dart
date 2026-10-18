import 'package:flutter/material.dart';
import 'heart_rate.dart';
import 'physical_activity.dart';
import 'blood_pressure.dart';
import 'glucose.dart';
import 'oxygen.dart';
import 'stability.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;

  
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
  }

  /// Start listening to voice
  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) async {
          String command = result.recognizedWords.toLowerCase();
          print("User said: $command");

          // Handle the voice command
          String reply = await _handleVoiceCommand(command);

          // Speak response
          _speak(reply);

          // Show SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(reply)),
          );
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Handle voice commands (navigate + speak)
  Future<String> _handleVoiceCommand(String command) async {
    // Remove all spaces for safety
    command = command.replaceAll(" ", "");

    if (command.contains("one")) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HeartRateScreen()));
      return "Opening Heart Rate.";
    }
    else if (command.contains("to")) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => GlucoseScreen()));
      return "Opening Glucose.";
    }
    else if (command.contains("free")) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BloodPressureScreen()));
      return "Opening Blood Pressure.";
    }
    else if (command.contains("four")) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OxygenScreen()));
      return "Opening Oxygen.";
    }
    else if (command.contains("five")) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PhysicalActivityScreen()));
      return "Opening Physical Activity.";
    }
    else if (command.contains("six")) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => StabilityScreen()));
      return "Opening Stability.";
    }

    return "Sorry, I didn’t understand. Please say a number from 1 to 6.";
  }

  /// Text-to-Speech
  Future<void> _speak(String message) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.9);
    await _tts.speak(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_sharp, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/welcome');
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
              Center(
                child: Column(
                  children: [
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Here is your latest health data:",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // Health Data Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: [
                    _healthButton(context, "Heart Rate", "75 bpm", Icons.favorite, Colors.red.shade200, HeartRateScreen()),
                    _healthButton(context, "Physical Activity", "10,200", Icons.directions_walk, Colors.green.shade200, PhysicalActivityScreen()),
                    _healthButton(context, "Blood Pressure", "120/80", Icons.monitor_heart, Colors.orange.shade200, BloodPressureScreen()),
                    _healthButton(context, "Glucose", "98 mg/dL", Icons.water_drop, Colors.purple.shade200, GlucoseScreen()),
                    _healthButton(context, "Oxygen", "98%", Icons.bubble_chart, Colors.blue.shade200, OxygenScreen()),
                    _healthButton(context, "Stability", "Good", Icons.stacked_line_chart, Colors.yellow.shade300, StabilityScreen()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor: _isListening ? Colors.red : Colors.teal,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 30),
      ),
    );
  }

  Widget _healthButton(BuildContext context, String title, String value, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.black54),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
