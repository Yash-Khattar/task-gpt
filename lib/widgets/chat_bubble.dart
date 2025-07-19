import 'dart:io';
import 'package:flutter/material.dart';
import '../common/colors.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';

class ChatBubble extends StatelessWidget {
  final String? text;
  final File? image;
  final String? imageUrl;
  final bool isUser;
  final bool isError;
  final VoidCallback? onRetry;

  const ChatBubble({Key? key, this.text, this.image, this.imageUrl, required this.isUser, this.isError = false, this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isError
        ? Colors.red
        : isUser
            ? AppColors.userMessage
            : AppColors.aiMessage;
    final textColor = isError ? Colors.white : AppColors.accent;
    String? displayText = text;
    if (isError && text?.startsWith('Error:') == true) {
      displayText = 'Something went wrong. Please try again.';
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isUser ? 18 : 6),
              topRight: Radius.circular(isUser ? 6 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    image!,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl!,
                    width: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 200,
                          height: 120,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              if (displayText != null)
                Padding(
                  padding: EdgeInsets.only(top: (image != null || imageUrl != null) ? 10 : 0),
                  child: isUser
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isError)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0, top: 2),
                                child: Icon(Icons.error_outline, color: Colors.white, size: 20),
                              ),
                            Expanded(
                              child: Text(
                                displayText,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (isError && onRetry != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: IconButton(
                                  icon: Icon(Icons.refresh, color: Colors.white),
                                  tooltip: 'Retry',
                                  onPressed: onRetry,
                                ),
                              ),
                          ],
                        )
                      : MarkdownBody(
                          data: displayText!,
                          styleSheet: MarkdownStyleSheet(
                            code: TextStyle(
                              backgroundColor: Colors.grey[200],
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            p: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          selectable: true,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 