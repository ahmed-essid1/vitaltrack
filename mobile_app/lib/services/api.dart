import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Update this to match the production URL or keep it for local testing
  static const String baseUrl = "http://127.0.0.1:8000";

  // Function to get heart rate prediction
  static Future<String?> getHeartRate(List<double> features) async {
    final url = Uri.parse('$baseUrl/predict/heart_rate');
    return _postRequest(url, features, 'heart_rate_prediction');
  }

  // Function to get blood pressure prediction
  static Future<Map<String, String>> getBloodPressure(List<double> features) async {
    final url = Uri.parse('$baseUrl/predict/hypertension');
    try {
      print("📡 Sending request to: $url");
      print("📊 Request Data: ${jsonEncode({"features": features})}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": features}),
      );

      print("🔄 Response Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "value": data['hypertension_prediction'].toString(),
          "category": data['blood_pressure_category'].toString(),
        };
      } else {
        return {"error": "Error: ${response.statusCode}"};
      }
    } catch (e) {
      print("❌ Error in getBloodPressure: $e");
      return {"error": "Failed to fetch hypertension"};
    }
  }

  // Function to get glucose (diabetes) prediction
  static Future<String?> getGlucose(List<double> features) async {
    final url = Uri.parse('$baseUrl/predict/diabetes');
    try {
      print("📡 Sending request to: $url");
      print("📊 Request Data: ${jsonEncode({"features": features})}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": features}),
      );

      print("🔄 Response Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Modify this line to handle glucose prediction
        return data['diabetes_prediction'].toString();
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      print("❌ Error in getGlucose: $e");
      return "Failed to fetch glucose data";
    }
  }

  // Function to get stability prediction
  static Future<String?> getStability(List<double> features) async {
    final url = Uri.parse('$baseUrl/predict/stability1'); // Ensure this matches your backend route
    return _postRequest(url, features, 'stability_prediction');
  }

  // Private function for making a POST request to the backend API
  static Future<String?> _postRequest(Uri url, List<dynamic> features, String key, {bool isList = false}) async {
    try {
      print("📡 Sending request to: $url");
      print("📊 Request Data: ${jsonEncode({"features": features})}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": features}),
      );

      print("🔄 Response Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return isList ? data[key][0].toString() : data[key].toString();
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      print("❌ Error in API request: $e");
      return "Failed to fetch data";
    }
  }

  // Function to get glucose (diabetes) prediction
  static Future<String?> getPhysicalActivity(List<double> features) async {
    final url = Uri.parse('$baseUrl/predict/activity');
    try {
      print("📡 Sending request to: $url");
      print("📊 Request Data: ${jsonEncode({"features": features})}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": features}),
      );

      print("🔄 Response Status Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Modify this line to handle glucose prediction
        return data['activity_prediction'].toString();
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      print("❌ Error in getPhysicalActivity: $e");
      return "Failed to fetch physical activity data";
    }
  }
}
