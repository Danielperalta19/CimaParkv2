import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  Future<void> _loginUsuario() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // 1. Iniciar sesión con Firebase Auth
      UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Buscar el tipo de usuario en la colección "usuarios"
      QuerySnapshot query =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('correo', isEqualTo: _emailController.text.trim())
              .get();

      if (query.docs.isEmpty) {
        throw Exception('Usuario no encontrado en la base de datos');
      }

      DocumentSnapshot userDoc = query.docs.first;

      String tipo = userDoc.get('tipo_usuario');

      // 3. Redireccionar según tipo
      if (tipo == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (tipo == 'alumno') {
        Navigator.pushReplacementNamed(context, '/alumno');
      } else {
        throw Exception('Tipo de usuario desconocido');
      }
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
      appBar: AppBar(title: const Text('Iniciar Sesión')),
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
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _loginUsuario,
                  child: const Text('Ingresar'),
                ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/registro',
                ); // Redirige a la página de registro
              },
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
          ],
        ),
      ),
    );
  }
}
