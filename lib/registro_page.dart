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

    try {
      // 1. Crear el usuario con Firebase Auth
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Crear documento del alumno en la colección 'alumnos'
      DocumentReference alumnoRef = await FirebaseFirestore.instance
          .collection('alumnos')
          .add({
            'nombre': _nombreController.text.trim(),
            'primer_apellido': _primerApellidoController.text.trim(),
            'segundo_apellido': _segundoApellidoController.text.trim(),
            'matricula': _matriculaController.text.trim(),
            // Si el vehículo_ref es necesario, puedes agregarlo como un campo
            'vehiculo_ref': null, // Si no se proporciona, lo dejamos como null
          });

      // 3. Crear documento de usuario en la colección 'usuarios'
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'correo': _emailController.text.trim(),
            'password':
                _passwordController.text
                    .trim(), // Puedes manejar la contraseña de manera segura
            'tipo_usuario': 'alumno',
            'tipo_ref':
                alumnoRef, // Aquí guardamos la referencia al documento de alumno
          });

      // 4. Redirigir a la pantalla de alumno
      Navigator.pushReplacementNamed(context, '/alumno');
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
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
      appBar: AppBar(title: const Text('Registrar Alumno')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _primerApellidoController,
              decoration: const InputDecoration(labelText: 'Primer Apellido'),
            ),
            TextField(
              controller: _segundoApellidoController,
              decoration: const InputDecoration(labelText: 'Segundo Apellido'),
            ),
            TextField(
              controller: _matriculaController,
              decoration: const InputDecoration(labelText: 'Matrícula'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _registrarAlumno,
                  child: const Text('Registrar'),
                ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/login',
                ); // Redirige al login
              },
              child: const Text('¿Ya tienes cuenta? Inicia sesión aquí'),
            ),
          ],
        ),
      ),
    );
  }
}
