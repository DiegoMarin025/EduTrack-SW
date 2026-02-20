import 'package:flutter/material.dart';
import 'package:app_calificaciones/pantallas/ayuda_screen.dart';
import '/pantallas/ayuda_screen.dart';

class EdutrackSupportApp extends StatelessWidget {
  const EdutrackSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soporte EduTrack',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: AyudaScreen(),
      debugShowCheckedModeBanner: false, // ← Esta línea quita el debug
    );
  }
}
