import 'package:chatgpt_clone/features/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common/colors.dart';
import 'providers/chat_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'ChatGPT Clone',
        theme: ThemeData(
          fontFamily: 'SF Pro Display',
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.accent,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            background: AppColors.background,
            onBackground: AppColors.accent,
            surface: Colors.white,
            onSurface: AppColors.accent,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.accent,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
          ),
        ),
        home: const ChatScreen(),
      ),
    );
  }
}

