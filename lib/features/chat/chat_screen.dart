import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../common/colors.dart';
import '../../widgets/chat_bubble.dart';
import '../../providers/chat_provider.dart';
import 'package:loading_indicator/loading_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  String? _inputError;
  String _searchQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optionally load history for a default conversation
    final provider = Provider.of<ChatProvider>(context, listen: false);
    if (provider.conversationId != null) {
      provider.loadHistory(provider.conversationId!);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _pickImage(BuildContext context) async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      final maxSize = 5 * 1024 * 1024; // 5MB
      final ext = pickedFile.path.split('.').last.toLowerCase();
      if (fileSize > maxSize) {
        _showImageError(context, 'Image must be less than 5MB.');
        return;
      }
      if (!(ext == 'jpg' || ext == 'jpeg' || ext == 'png')) {
        _showImageError(context, 'Only JPG, JPEG, and PNG images are allowed.');
        return;
      }
      final url = await provider.uploadImage(file);
      if (url != null) {
        await provider.sendMessage('[Image]', imageUrl: url);
        _scrollToBottom();
      }
    }
  }

  void _showImageError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _sendMessage(BuildContext context) async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _inputError = 'Message cannot be empty.';
      });
      return;
    }
    setState(() {
      _inputError = null;
    });
    _controller.clear();
    await provider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            drawer: Drawer(
              backgroundColor: const Color(0xFFF8F9FB),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chat History',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF22232A),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              style: const TextStyle(fontSize: 16, color: Color(0xFF22232A)),
                              decoration: InputDecoration(
                                hintText: 'Search chats...',
                                hintStyle: const TextStyle(color: Color(0xFFB0B3C7)),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search, color: AppColors.imageButton),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              icon: const Icon(Icons.add, size: 22),
                              label: const Text('New Chat'),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await Provider.of<ChatProvider>(context, listen: false).createNewChat();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        color: const Color(0xFFE6E8F0),
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: Provider.of<ChatProvider>(context, listen: false).getChatHistoryList(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final history = snapshot.data ?? [];
                          if (history.isEmpty) {
                            return const Center(child: Text('No past chats.', style: TextStyle(color: Color(0xFFB0B3C7), fontSize: 16)));
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            itemCount: history.where((chat) {
                              final title = (chat['title'] ?? chat['conversation_id'] ?? 'Chat').toString();
                              return _searchQuery.isEmpty || title.toLowerCase().contains(_searchQuery.toLowerCase());
                            }).length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final filtered = history.where((chat) {
                                final title = (chat['title'] ?? chat['conversation_id'] ?? 'Chat').toString();
                                return _searchQuery.isEmpty || title.toLowerCase().contains(_searchQuery.toLowerCase());
                              }).toList();
                              final chat = filtered[index];
                              final title = chat['title'] ?? chat['conversation_id'] ?? 'Chat';
                              final ts = chat['created_at'] != null ? DateTime.tryParse(chat['created_at']) : null;
                              final subtitle = ts != null ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}' : '';
                              return ListTile(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF22232A))),
                                subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFB0B3C7))) : null,
                                leading: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 22),
                                ),
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await Provider.of<ChatProvider>(context, listen: false).loadHistory(chat['conversation_id']);
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                horizontalTitleGap: 10,
                                minVerticalPadding: 0,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        color: const Color(0xFFE6E8F0),
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            appBar: AppBar(
              title: const Text('ChatGPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accent,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.selectedModel,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.accent),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      items: ['gemini-2.5-flash', 'gemini-2.5-pro'].map((model) {
                        return DropdownMenuItem<String>(
                          value: model,
                          child: Row(
                            children: [
                             
                              Text(model),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null && value != provider.selectedModel) {
                          await provider.setModel(value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                          itemCount: provider.messages.length,
                          itemBuilder: (context, index) {
                            final msg = provider.messages[index];
                            return ChatBubble(
                              text: msg.text,
                              imageUrl: msg.imageUrl,
                              isUser: msg.isUser,
                              isError: msg.text != null && msg.text!.startsWith('Error:'),
                              onRetry: msg.isUser
                                  ? null
                                  : () async {
                                      final provider = Provider.of<ChatProvider>(context, listen: false);
                                      final userMsg = provider.messages.reversed.firstWhere(
                                        (m) => m.isUser,
                                        orElse: () => ChatMessage(text: '', isUser: true),
                                      );
                                      if (userMsg.text != null && userMsg.text!.isNotEmpty) {
                                        await provider.sendMessage(userMsg.text!);
                                      }
                                    },
                            );
                          },
                        ),
                      ),
                      if (provider.loading)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 36,
                            width: 60,
                            child: LoadingIndicator(
                              indicatorType: Indicator.ballPulse,
                              colors: [AppColors.primary, AppColors.accent, AppColors.imageButton],
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      const SizedBox(height: 70), // Space for the floating input bar
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(32),
                        color: Colors.white,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.image, color: AppColors.imageButton),
                                onPressed: () => _pickImage(context),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  minLines: 1,
                                  maxLines: 4,
                                  
                                  decoration: InputDecoration(
                                    fillColor: Colors.white,
                                    hintText: 'Type your message...',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    errorText: _inputError,
                                  ),
                                  onChanged: (_) {
                                    if (_inputError != null && _controller.text.trim().isNotEmpty) {
                                      setState(() {
                                        _inputError = null;
                                      });
                                    }
                                    setState(() {});
                                  },
                                  onSubmitted: (_) => _sendMessage(context),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _controller.text.trim().isEmpty ? null : () => _sendMessage(context),
                                child: AnimatedScale(
                                  scale: _controller.text.trim().isEmpty ? 0.9 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _controller.text.trim().isEmpty ? AppColors.sendButton.withOpacity(0.5) : AppColors.sendButton,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(Icons.send, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
