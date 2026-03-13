import 'package:flutter/material.dart';
import 'login_page.dart'; // Import relativo

void main() {
  runApp(const EduTrackApp());
}

class EduTrackApp extends StatelessWidget {
  const EduTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[900]!),
        useMaterial3: true,
      ),
      // Asegúrate de que LoginPage() no pida parámetros que no le pases
      home: const LoginPage(),
    );
  }
}