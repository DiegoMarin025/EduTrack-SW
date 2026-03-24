import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'main_layout.dart';
import 'pantallasmaestros/main_layout_maestros_screen.dart';
import 'services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController _matriculaHijoController =
      TextEditingController();

  String userType = "Tutor";
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _matriculaHijoController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showSnackBar("Por favor completa todos los campos");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar("Las contraseñas no coinciden");
      return;
    }

    if (passwordController.text.length < 6) {
      _showSnackBar("La contraseña debe tener al menos 6 caracteres");
      return;
    }

    if (userType == "Tutor" && _matriculaHijoController.text.trim().isEmpty) {
      _showSnackBar("Ingresa la matrícula o ID del alumno a vincular");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.registerUser(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        userType,
        matriculaHijo: userType == "Tutor"
            ? _matriculaHijoController.text.trim()
            : null,
      );

      final usuario = await ApiService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', emailController.text.trim());
      await prefs.setString('saved_password', passwordController.text.trim());
      await prefs.setString(
        'saved_userType',
        (usuario['rol'] ?? userType).toString().toLowerCase(),
      );
      await prefs.setString('saved_name', usuario['nombre']);

      final int userId = int.tryParse(usuario['id'].toString()) ?? 0;
      await prefs.setInt('saved_id', userId);

      int? linkedStudentId = int.tryParse(
        (usuario['alumno_id_vinculado'] ?? '').toString(),
      );
      final rolReal = (usuario['rol'] ?? userType).toString().toLowerCase();
      if (rolReal == 'tutor' && (linkedStudentId == null || linkedStudentId <= 0)) {
        final linked = await ApiService.getTutorAlumnoVinculado(userId);
        linkedStudentId = linked?.id;
      }
      if (linkedStudentId != null && linkedStudentId > 0) {
        await prefs.setInt('saved_linked_student_id', linkedStudentId);
      } else {
        await prefs.remove('saved_linked_student_id');
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bienvenido ${usuario['nombre']}"),
          backgroundColor: Colors.green,
        ),
      );

      _navegarAlHome(userId);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _navegarAlHome(int userId) {
    final raw = nameController.text.trim();
    final displayName = raw.isNotEmpty ? raw.split(' ').first : 'Usuario';

    if (userType == "Maestro" || userType == "Profesor") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutMaestros()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MainLayout(username: displayName, usuarioId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.person_add,
                  size: 90,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Registro",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: _decoration(
                    "Nombre completo",
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration(
                    "Correo electrónico",
                    Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: userType,
                  items: const [
                    DropdownMenuItem(
                      value: "Tutor",
                      child: Text("Padre/Tutor"),
                    ),
                    DropdownMenuItem(value: "Maestro", child: Text("Maestro")),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => userType = value);
                  },
                  decoration: _decoration(
                    "Tipo de usuario",
                    Icons.school_outlined,
                  ),
                ),
                const SizedBox(height: 15),
                if (userType == "Tutor") ...[
                  TextField(
                    controller: _matriculaHijoController,
                    keyboardType: TextInputType.number,
                    decoration: _decoration(
                      "Matrícula o ID del alumno",
                      Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: _decoration(
                    "Contraseña",
                    Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: _decoration(
                    "Confirmar contraseña",
                    Icons.lock_reset,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Registrar",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
