import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'register_page.dart';
import 'main_layout.dart';
import 'pantallasmaestros/main_layout_maestros_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Llamamos al login (el servidor decide qué rol es)
      final usuario = await ApiService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      // 2. Obtenemos el rol real desde la respuesta del servidor
      // Aseguramos que venga en minúsculas para comparar fácil
      final String rolReal = (usuario['rol'] ?? 'alumno')
          .toString()
          .toLowerCase();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', emailController.text.trim());
      await prefs.setString('saved_password', passwordController.text.trim());

      // Guardamos el rol detectado
      await prefs.setString('saved_userType', rolReal);

      // Guardamos ID y nombre
      int userId = usuario['id'];
      await prefs.setInt('saved_id', userId);
      await prefs.setString('saved_name', usuario['nombre']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bienvenido ${usuario['nombre']}"),
            backgroundColor: Colors.green,
          ),
        );
        // Navegamos pasando el rol detectado
        _navegarAlHome(usuario, rolReal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navegarAlHome(Map<String, dynamic> usuario, String rol) {
    final rawName = usuario['nombre'] ?? 'Usuario';
    final displayName = rawName.toString().split(' ')[0];
    final int userId = usuario['id'];

    // Lógica de redirección automática
    if (rol == "profesor" || rol == "maestro") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutMaestros()),
      );
    } else {
      // Por defecto va a Alumno
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MainLayout(username: displayName, usuarioId: userId),
        ),
      );
    }
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
                // LOGOTIPO (o Ícono por defecto)
                Image.asset(
                  'lib/image/logotipo.png',
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school_rounded,
                      size: 90,
                      color: Colors.deepPurple,
                    );
                  },
                ),
                const Text(
                  "Inicio de Sesión",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // CAMPO CORREO
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // CAMPO CONTRASEÑA
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                // YA NO HAY DROPDOWN DE ROL AQUÍ 🎉
                const SizedBox(height: 20),

                // BOTÓN INGRESAR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
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
                            "Ingresar",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // IR A REGISTRO
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text("¿No tienes cuenta? Regístrate"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
