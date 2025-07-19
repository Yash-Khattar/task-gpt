import 'dart:convert';
import 'dart:io';
import 'package:chatgpt_clone/core/url.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static const String baseUrl = Url.baseUrl;

  /// For Gemini, use 'gemini-pro' as the model for text, or 'gemini-pro-vision' for images (if supported by backend)
  Future<String> sendMessage({
    required String conversationId,
    required String message,
    String model = 'gemini-pro', // Default to Gemini
    String? imageUrl,
    List<Map<String, dynamic>>? previousMessages,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'conversation_id': conversationId,
        'message': message,
        'model': model,
        if (imageUrl != null) 'image_url': imageUrl,
        if (previousMessages != null) 'context': previousMessages,
      }),
    );
    print(response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['ai_response'] as String;
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(String conversationId) async {
    final response = await http.get(Uri.parse('$baseUrl/history/$conversationId'));
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['messages'] ?? []);
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllConversations() async {
    final response = await http.get(Uri.parse('$baseUrl/history'));
    print(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load conversations: ${response.body}');
    }
  }

  Future<String> createNewChat() async {
    final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
    // Do not send a welcome message by default
    return conversationId;
  }

  Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    print(response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'] as String;
    } else {
      throw Exception('Failed to upload image: ${response.body}');
    }
  }
}
