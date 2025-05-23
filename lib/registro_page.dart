import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _primerApellidoController = TextEditingController();
  final _segundoApellidoController = TextEditingController();
  final _matriculaController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  Future<void> _registrarAlumno() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final email = _emailController.text.trim();

    if (!email.endsWith('@uabc.edu.mx')) {
      setState(() {
        _isLoading = false;
        _error = 'Solo se permiten correos institucionales @uabc.edu.mx';
      });
      return;
    }

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _nombreController.text.trim().isEmpty ||
        _primerApellidoController.text.trim().isEmpty ||
        _matriculaController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Por favor, completa todos los campos';
      });
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(_matriculaController.text.trim())) {
      setState(() {
        _isLoading = false;
        _error = 'La matrícula debe contener solo números';
      });
      return;
    }

    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      DocumentReference alumnoRef = await FirebaseFirestore.instance
          .collection('alumnos')
          .add({
            'nombre': _nombreController.text.trim(),
            'primer_apellido': _primerApellidoController.text.trim(),
            'segundo_apellido': _segundoApellidoController.text.trim(),
            'matricula': _matriculaController.text.trim(),
            'vehiculo_ref': null,
          });

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'correo': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'tipo_usuario': 'alumno',
            'tipo_ref': alumnoRef,
          });

      Navigator.pushReplacementNamed(context, '/perfil');
    } on FirebaseAuthException catch (e) {
      String mensajeError;
      switch (e.code) {
        case 'email-already-in-use':
          mensajeError =
              'Este correo ya está registrado. Intenta iniciar sesión.';
          break;
        case 'invalid-email':
          mensajeError = 'El correo electrónico no es válido.';
          break;
        case 'weak-password':
          mensajeError =
              'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
          break;
        case 'missing-password':
          mensajeError = 'La contraseña no puede estar vacía.';
          break;
        default:
          mensajeError = 'Error de registro: ${e.message}';
      }
      setState(() {
        _error = mensajeError;
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error inesperado: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/fondo.jpeg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(child: Image.asset('assets/logo.png', height: 125)),
                    const SizedBox(height: 20),

                    _buildLabeledTextField('Correo', _emailController),
                    _buildLabeledTextField(
                      'Contraseña',
                      _passwordController,
                      isPassword: true,
                    ),
                    _buildLabeledTextField('Nombre', _nombreController),
                    _buildLabeledTextField(
                      'Primer Apellido',
                      _primerApellidoController,
                    ),
                    _buildLabeledTextField(
                      'Segundo Apellido',
                      _segundoApellidoController,
                    ),
                    _buildLabeledTextField('Matrícula', _matriculaController),

                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _registrarAlumno,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 100,
                              vertical: 20,
                            ),
                          ),
                          child: const Text(
                            'Registrar',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),

                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        '¿Ya tienes cuenta? Inicia sesión aquí',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
