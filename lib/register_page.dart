import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _matriculaHijoController = TextEditingController();

  // Estado del formulario
  String _rolSeleccionado = 'tutor'; 
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Función de Registro
  Future<void> _registrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final Map<String, dynamic> requestBody = {
          'nombre': _nombreController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'rol': _rolSeleccionado,
        };

        if (_rolSeleccionado == 'tutor') {
          requestBody['matricula_hijo'] = _matriculaHijoController.text;
        }

        final response = await http.post(
          Uri.parse('http://localhost:3000/register'), 
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 201) {
          _showSnackBar('¡Registro exitoso!', Colors.green);
          Navigator.pop(context);
        } else {
          final errorData = jsonDecode(response.body);
          _showSnackBar(errorData['message'] ?? 'Error al registrar', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Error de conexión con el servidor', Colors.red);
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('EduTrack', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
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
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ÍCONO DINÁMICO (Mantiene la ayuda visual)
                        Icon(
                          _rolSeleccionado == 'tutor' ? Icons.family_restroom : Icons.school, 
                          size: 80, 
                          color: Colors.blue[900]
                        ),
                        SizedBox(height: 16),
                        
                        // TÍTULO SIMPLIFICADO SEGÚN TU PETICIÓN
                        Text(
                          'Registro',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                        ),
                        SizedBox(height: 32),

                        // Selector de Rol
                        _buildDropdownRol(),
                        SizedBox(height: 20),

                        _buildTextField(
                          controller: _nombreController,
                          label: 'Nombre Completo',
                          icon: Icons.person_outline,
                          validator: (value) => value!.isEmpty ? 'Ingresa tu nombre' : null,
                        ),
                        SizedBox(height: 20),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Correo Electrónico',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa un correo';
                            if (!value.contains('@')) return 'Ingresa un correo válido';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Campo de matrícula solo si es Tutor
                        if (_rolSeleccionado == 'tutor') ...[
                          _buildTextField(
                            controller: _matriculaHijoController,
                            label: 'Matrícula del Hijo',
                            icon: Icons.badge_outlined,
                            hint: 'Ej. 202300456',
                            validator: (value) => value!.isEmpty ? 'La matrícula es obligatoria' : null,
                          ),
                          SizedBox(height: 20),
                        ],

                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          obscure: _obscurePassword,
                          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                          validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                        ),
                        SizedBox(height: 20),

                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar Contraseña',
                          obscure: _obscureConfirmPassword,
                          onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          validator: (value) => value != _passwordController.text ? 'No coinciden' : null,
                        ),
                        SizedBox(height: 40),

                        _isLoading
                            ? CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _registrar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[900],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 5,
                                  ),
                                  child: Text('CONTINUAR', 
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES DE DISEÑO ---

  Widget _buildDropdownRol() {
    return DropdownButtonFormField<String>(
      value: _rolSeleccionado,
      decoration: InputDecoration(
        labelText: 'Tipo de Usuario',
        prefixIcon: Icon(Icons.people_alt_outlined, color: Colors.blue[900]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: [
        DropdownMenuItem(value: 'tutor', child: Text('Tutor / Padre')),
        DropdownMenuItem(value: 'docente', child: Text('Docente / Maestro')),
      ],
      onChanged: (value) => setState(() => _rolSeleccionado = value!),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[900]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[900]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blue[900]),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.blue[900]),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[900]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }
}