import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AgregarUsuarioPage extends StatefulWidget {
  const AgregarUsuarioPage({super.key});

  @override
  State<AgregarUsuarioPage> createState() => _AgregarUsuarioPageState();
}

class _AgregarUsuarioPageState extends State<AgregarUsuarioPage> {
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
      // Crear usuario en Firebase Auth
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Crear documento en la colección 'alumnos'
      DocumentReference alumnoRef = await FirebaseFirestore.instance
          .collection('alumnos')
          .add({
            'nombre': _nombreController.text.trim(),
            'primer_apellido': _primerApellidoController.text.trim(),
            'segundo_apellido': _segundoApellidoController.text.trim(),
            'matricula': _matriculaController.text.trim(),
            'vehiculo_ref': null,
          });

      // Crear documento en la colección 'usuarios'
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'correo': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
            'tipo_usuario': 'alumno',
            'tipo_ref': alumnoRef,
          });

      if (mounted) {
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Éxito'),
                content: const Text('Alumno registrado correctamente.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(
                        context,
                      ).pop(); // Regresar a la pantalla anterior
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensajeError;
      switch (e.code) {
        case 'email-already-in-use':
          mensajeError = 'Este correo ya está registrado.';
          break;
        case 'invalid-email':
          mensajeError = 'El correo electrónico no es válido.';
          break;
        case 'weak-password':
          mensajeError = 'La contraseña es muy débil.';
          break;
        default:
          mensajeError = 'Error de registro: ${e.message}';
      }
      setState(() {
        _error = mensajeError;
      });
    } catch (e) {
      setState(() {
        _error = 'Error inesperado: ${e.toString()}';
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
      appBar: AppBar(
        title: const Text('Agregar Alumno'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildField('Correo', _emailController),
            _buildField('Contraseña', _passwordController, isPassword: true),
            _buildField('Nombre', _nombreController),
            _buildField('Primer Apellido', _primerApellidoController),
            _buildField('Segundo Apellido', _segundoApellidoController),
            _buildField('Matrícula', _matriculaController),

            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  onPressed: _registrarAlumno,
                  label: const Text('Registrar Alumno'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
