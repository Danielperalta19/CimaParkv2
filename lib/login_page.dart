import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: '@uabc.edu.mx');
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  Future<void> _loginUsuario() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = cred.user!.uid;

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();

      if (!userDoc.exists) {
        setState(() {
          _error = 'El usuario no está registrado en la base de datos.';
          _isLoading = false;
        });
        return;
      }

      String tipoUsuario = userDoc.get('tipo_usuario');

      if (tipoUsuario == 'alumno') {
        DocumentReference? alumnoRef = userDoc.get('tipo_ref');

        if (alumnoRef == null) {
          setState(() {
            _error = 'No se encontró referencia al alumno.';
            _isLoading = false;
          });
          return;
        }

        DocumentSnapshot alumnoDoc = await alumnoRef.get();

        if (!alumnoDoc.exists) {
          setState(() {
            _error = 'No se encontró información del alumno.';
            _isLoading = false;
          });
          return;
        }

        var alumnoData = alumnoDoc.data() as Map<String, dynamic>;

        if (alumnoData.containsKey('vehiculo_ref') &&
            alumnoData['vehiculo_ref'] != null) {
          Navigator.pushReplacementNamed(context, '/estacionamiento');
        } else {
          Navigator.pushReplacementNamed(context, '/perfil');
        }
      } else if (tipoUsuario == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        setState(() {
          _error = 'Tipo de usuario desconocido.';
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-credential':
            _error = 'Correo o contraseña incorrectos.';
            break;
          case 'missing-password':
            _error = 'Por favor ingresa tu contraseña.';
            break;
          case 'invalid-email':
            _error = 'Por favor ingresa un correo válido.';
            break;
          default:
            _error = 'Error de autenticación: ${e.message}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error: ${e.toString()}';
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Image.asset('assets/logo.png', height: 300)),
                    const SizedBox(height: 10),

                    // Texto "Correo"
                    const Text(
                      'Correo',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 5),

                    // TextField de correo
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: '@uabc.edu.mx',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Texto "Contraseña"
                    const Text(
                      'Contraseña',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 5),

                    // TextField de contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botón ingresar
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Center(
                          child: ElevatedButton(
                            onPressed: _loginUsuario,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 150,
                                vertical: 25,
                              ),
                            ),
                            child: const Text(
                              'Ingresar',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),

                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Center(
                          child: Text(
                            _error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Texto para registrarse
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/registro');
                        },
                        child: const Text(
                          '¿No tienes cuenta? Regístrate aquí',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
}
