import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

import 'main_layout.dart';
import 'pantallasmaestros/main_layout_maestros_screen.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isHovering = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ======================================================
  // 🔐 LÓGICA DE LOGIN CON FIREBASE (Segura y limpia)
  // ======================================================
  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Iniciar sesión en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // 2. Traer los datos del usuario desde Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw "No se encontró información del usuario en la base de datos.";
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final String rolReal = (userData['rol'] ?? 'tutor').toString().toLowerCase();
      final String nombreFull = userData['nombre'] ?? 'Usuario';

      // 3. Guardar en SharedPreferences 
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', emailController.text.trim());
      await prefs.setString('saved_name', nombreFull);
      await prefs.setString('saved_userType', rolReal);
      await prefs.setString('saved_uid', uid);
      
      int userIdInt = uid.hashCode;
      await prefs.setInt('saved_id', userIdInt);

      // 🟢 CORRECCIÓN VITAL: Guardar como int, no como String
      if (userData.containsKey('matriculaHijo') && userData['matriculaHijo'] != null) {
        int matriculaGuardada = int.tryParse(userData['matriculaHijo'].toString()) ?? 0;
        if (matriculaGuardada > 0) {
          await prefs.setInt('saved_linked_student_id', matriculaGuardada);
        }
      }

      if (mounted) {
        _navegarAlHome(userData, rolReal);
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error al ingresar";
      // 🟢 MANEJO DE ERRORES MODERNOS DE FIREBASE
      if (e.code == 'user-not-found' || e.code == 'invalid-email') mensaje = "El correo no está registrado";
      else if (e.code == 'wrong-password') mensaje = "Contraseña incorrecta";
      else if (e.code == 'invalid-credential') mensaje = "Correo o contraseña incorrectos";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navegarAlHome(Map<String, dynamic> usuario, String rol) {
    final rawName = usuario['nombre'] ?? 'Usuario';
    final displayName = rawName.toString().split(' ')[0];
    final String uid = usuario['uid'] ?? "";

    if (rol == 'profesor' || rol == 'maestro') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutMaestros()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MainLayout(username: displayName, usuarioId: uid.hashCode),
        ),
      );
    }
  }

  // ======================================================
  // 🎨 DISEÑO ORIGINAL (SIN TOCAR NADA)
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _buildLoginCard(),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bienvenido a EduTrack",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Gestión académica inteligente\npara maestros y padres",
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 50),
                  Center(
                    child: Image.asset(
                      'lib/image/login.png',
                      width: 350,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(child: SizedBox(width: 420, child: _buildLoginCard())),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('lib/image/logotipo.png', height: 200),
          const SizedBox(height: 25),
          const Text(
            'Iniciar Sesión',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 30),
          _modernTextField(
            controller: emailController,
            hint: 'Correo electrónico',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 20),
          _modernTextField(
            controller: passwordController,
            hint: 'Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 30),
          _modernButton(),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
            child: const Text(
              '¿No tienes cuenta? Regístrate',
              style: TextStyle(color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _modernButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _isLoading ? null : login,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovering
                ? const Color(0xFF1E40AF)
                : const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 8,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Ingresar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}