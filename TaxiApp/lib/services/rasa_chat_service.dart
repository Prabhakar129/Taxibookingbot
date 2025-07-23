import 'dart:convert';
import 'package:http/http.dart' as http;

class RasaChatService {
  final String rasaUrl = "http://localhost:5005/webhooks/rest/webhook";

  Future<List<Map<String, dynamic>>> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(rasaUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "sender": "user",
        "message": message,
      }),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      if (data.isEmpty) {
        return [
          {"text": "No response from bot", "buttons": []}
        ];
      }

      List<Map<String, dynamic>> botResponses = [];
      for (var item in data) {
        botResponses.add({
          "text": item['text'] ?? "",
          "buttons": item['buttons'] ?? []
        });
      }

      return botResponses;
    } else {
      throw Exception("Failed to connect to Rasa server");
    }
  }
}
