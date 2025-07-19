import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';

class ChatMessage {
  final String? text;
  final String? imageUrl;
  final bool isUser;
  ChatMessage({this.text, this.imageUrl, required this.isUser});
}

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  List<ChatMessage> _messages = [];
  String? _conversationId;
  String _selectedModel = 'gemini-2.5-flash';
  bool _loading = false;

  List<ChatMessage> get messages => _messages;
  String? get conversationId => _conversationId;
  String get selectedModel => _selectedModel;
  bool get loading => _loading;

  ChatProvider() {
    _initModel();
  }

  Future<void> _initModel() async {
    final prefs = await SharedPreferences.getInstance();
    final model = prefs.getString('selected_model');
    if (model != null && model.isNotEmpty) {
      _selectedModel = model;
    } else {
      _selectedModel = 'gemini-2.5-flash';
      await prefs.setString('selected_model', _selectedModel);
    }
    notifyListeners();
  }

  Future<void> setModel(String model) async {
    _selectedModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_model', model);
    notifyListeners();
  }

  Future<void> loadHistory(String conversationId) async {
    _conversationId = conversationId;
    _loading = true;
    notifyListeners();
    try {
      final history = await _service.getHistory(conversationId);
      _messages = history.map((msg) => ChatMessage(
        text: msg['text'],
        imageUrl: msg['image_url'],
        isUser: msg['is_user'] ?? false,
      )).toList();
    } catch (e) {
      _messages = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? imageUrl}) async {
    _conversationId ??= DateTime.now().millisecondsSinceEpoch.toString();
    _messages.add(ChatMessage(text: text, imageUrl: imageUrl, isUser: true));
    _loading = true;
    notifyListeners();
    try {
      // Prepare context: last 10 messages (excluding the current user message)
      final contextMessages = _messages
          .take(_messages.length - 1)
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .map((msg) => {
                'text': msg.text,
                'image_url': msg.imageUrl,
                'is_user': msg.isUser,
              })
          .toList();
      final aiResponse = await _service.sendMessage(
        conversationId: _conversationId!,
        message: text,
        model: _selectedModel,
        imageUrl: imageUrl,
        previousMessages: contextMessages.isNotEmpty ? contextMessages : null,
      );
      _messages.add(ChatMessage(text: aiResponse, isUser: false));
    } catch (e) {
      _messages.add(ChatMessage(text: 'Error: Sorry, something went wrong. Please check your connection or try again later.', isUser: false));
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      return await _service.uploadImage(imageFile);
    } catch (e) {
      // Show a user-friendly error message for image upload failures
      _messages.add(ChatMessage(text: 'Error: Image upload failed. Please try again with a different image.', isUser: false));
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistoryList() async {
    try {
      return await _service.getAllConversations();
    } catch (e) {
      return [];
    }
  }

  Future<void> createNewChat() async {
    _loading = true;
    notifyListeners();
    try {
      final newId = await _service.createNewChat();
      await loadHistory(newId);
    } catch (e) {
      // handle error
    }
    _loading = false;
    notifyListeners();
  }

  void resetChat() {
    _messages = [];
    _conversationId = null;
    notifyListeners();
  }
}
