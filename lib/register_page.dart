import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'login_page.dart';
import 'main_layout.dart';
import 'pantallasmaestros/main_layout_maestros_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String userType = "Alumno";
  bool _isLoading = false;

  // VARIABLES PARA VISIBILIDAD DE CONTRASEÑA 👁️
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void register() async {
    // 1. Validar campos vacíos
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos")),
      );
      return;
    }

    // 2. Validar coincidencia
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    // 3. Validar longitud
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La contraseña debe tener al menos 6 caracteres"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 4. Registro en DB (AQUÍ SÍ ENVIAMOS EL userType)
      await ApiService.registerUser(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        userType, // <--- Correcto: El registro necesita saber qué rol crear
      );

      // 5. Auto-Login (CORREGIDO: YA NO ENVIAMOS userType)
      // La API ahora detecta el rol automáticamente
      final usuario = await ApiService.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
        // userType, <--- ELIMINADO: Esto causaba el error
      );

      // 6. Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', emailController.text.trim());
      await prefs.setString('saved_password', passwordController.text.trim());
      await prefs.setString('saved_userType', userType);
      await prefs.setString('saved_name', usuario['nombre']);

      final int userId = int.tryParse(usuario['id'].toString()) ?? 0;
      await prefs.setInt('saved_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("¡Bienvenido ${usuario['nombre']}!"),
            backgroundColor: Colors.green,
          ),
        );
        // Navegar
        _navegarAlHome(userId);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navegarAlHome(int userId) {
    final raw = nameController.text.trim();
    final displayName = raw.isNotEmpty ? raw.split(' ')[0] : 'Usuario';

    if (userType == "Maestro" || userType == "Profesor") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutMaestros()),
      );
    } else {
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
                const Icon(
                  Icons.person_add,
                  size: 90,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Registro",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Nombre
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nombre completo",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Correo
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Correo electrónico",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Tipo usuario
                DropdownButtonFormField<String>(
                  value: userType,
                  items: const [
                    DropdownMenuItem(value: "Alumno", child: Text("Alumno")),
                    DropdownMenuItem(value: "Maestro", child: Text("Maestro")),
                  ],
                  onChanged: (value) {
                    setState(() => userType = value.toString());
                  },
                  decoration: InputDecoration(
                    labelText: "Tipo de usuario",
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // --- CONTRASEÑA (CON OJITO) ---
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword, // Variable de estado
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
                const SizedBox(height: 15),

                // --- CONFIRMAR CONTRASEÑA (CON OJITO) ---
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword, // Variable de estado
                  decoration: InputDecoration(
                    labelText: "Confirmar Contraseña",
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botón Registrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : register,
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
                            "Registrar",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Ir al Login
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
}
