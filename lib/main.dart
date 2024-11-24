import 'package:flutter/material.dart';
import 'loading_screen.dart';
import 'voice_screen.dart';
import 'hotel_all.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoadingScreen(), // 시작할 때 LoadingScreen을 표시
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  LoadingScreenState createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // 일정 시간 후에 VoiceScreen으로 전환
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Navigator를 사용하여 화면 전환
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VoiceScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: CircularProgressIndicator(), // 로딩 화면 예시
      ),
    );
  }
}