import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- Nuevo
import 'firebase_options.dart'; // <--- El archivo que generaste
import 'login_page.dart';

void main() async { // <--- Agregamos async
  WidgetsFlutterBinding.ensureInitialized();
  
  // Iniciamos Firebase antes de lanzar la App
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const LoginPage(),
    );
  }
}