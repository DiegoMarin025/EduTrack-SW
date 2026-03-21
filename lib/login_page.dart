import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORTS DE TUS PANTALLAS ---
import 'main_layout.dart';
import 'register_page.dart';
// Según tu explorador, esta es la ruta exacta desde lib/
import 'pantallasmaestros/main_layout_maestros_screen.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // LÓGICA DE LOGIN
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'correo': _emailController.text.trim(),
            'contrasena': _passwordController.text.trim(),
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final usuario = data['usuario'];

          final String rolEnBD = usuario['rol']; 
          final int userId = usuario['id'];
          final String nombreUsuario = usuario['nombre'];

          // Guardamos sesión local
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', userId);
          await prefs.setString('rol', rolEnBD);
          await prefs.setInt('saved_id', userId);
          await prefs.setString('saved_name', nombreUsuario);
          await prefs.setString(
            'saved_username',
            _emailController.text.trim(),
          );
          await prefs.setString('saved_userType', rolEnBD);

          if (rolEnBD == 'alumno' || rolEnBD == 'tutor') {
            // REDIRECCIÓN A TUTORES
            // Pasamos userId y username para que no marque error en MainLayout
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainLayout(
                  usuarioId: userId, 
                  username: nombreUsuario,
                ),
              ),
            );
          } else if (rolEnBD == 'profesor') {
            // REDIRECCIÓN A MAESTROS
            _showSnackBar('¡Bienvenido Profesor $nombreUsuario!', Colors.blue);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainLayoutMaestros(),
              ),
            );
          }
        } else {
          _showSnackBar('Credenciales incorrectas (Revisa la BD)', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Error de conexión: Verifica tu servidor', Colors.orange);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: _buildLoginCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.blue[900]),
              SizedBox(height: 16),
              Text(
                'EduTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 32),
              
              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                icon: Icons.email_outlined,
              ),
              SizedBox(height: 20),
              
              _buildTextField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              SizedBox(height: 32),

              _isLoading ? CircularProgressIndicator() : _modernButton(),

              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                ),
                child: Text(
                  '¿No tienes cuenta? Regístrate',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[900]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _modernButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Text(
          'INICIAR SESIÓN',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
