import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FormularioUsuario extends StatefulWidget {
  const FormularioUsuario({super.key});

  @override
  State<FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<FormularioUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _tipoUsuario = 'alumno'; // valor por defecto

  bool _isLoading = false;
  String _mensajeError = '';

  Future<void> _registrarUsuario() async {
    setState(() {
      _isLoading = true;
      _mensajeError = '';
    });

    try {
      // 1. Crear usuario en Firebase Authentication
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Crear documento en la colección correspondiente
      DocumentReference tipoRef;
      if (_tipoUsuario == 'alumno') {
        tipoRef = await FirebaseFirestore.instance.collection('alumnos').add({
          'email': _emailController.text.trim(),
          // puedes agregar más datos si quieres
        });
      } else {
        tipoRef = await FirebaseFirestore.instance.collection('admins').add({
          'email': _emailController.text.trim(),
        });
      }

      // 3. Agregar usuario a la colección general "usuarios"
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCred.user!.uid)
          .set({
            'correo': _emailController.text.trim(),
            'tipo_usuario': _tipoUsuario,
            'tipo_ref': tipoRef,
          });

      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado con éxito')),
      );

      Navigator.pop(context); // Regresar a pantalla anterior
    } catch (e) {
      setState(() {
        _mensajeError = 'Error: ${e.toString()}';
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
      appBar: AppBar(title: const Text('Registrar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator:
                    (value) =>
                        value == null || !value.contains('@')
                            ? 'Correo inválido'
                            : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator:
                    (value) =>
                        value == null || value.length < 6
                            ? 'Mínimo 6 caracteres'
                            : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoUsuario,
                items: const [
                  DropdownMenuItem(value: 'alumno', child: Text('Alumno')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoUsuario = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Tipo de usuario'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _registrarUsuario();
                      }
                    },
                    child: const Text('Registrar'),
                  ),
              if (_mensajeError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_mensajeError, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
