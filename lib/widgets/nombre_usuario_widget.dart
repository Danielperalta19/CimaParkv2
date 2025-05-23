import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NombreUsuarioWidget extends StatelessWidget {
  const NombreUsuarioWidget({super.key});

  Future<String> obtenerNombreUsuario() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Cambia 'usuarios' y 'alumno' por los nombres reales si son distintos
    final userDoc =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final alumnoRef = userDoc['tipo_ref'] as DocumentReference;
    final alumnoDoc = await alumnoRef.get();

    return alumnoDoc['nombre'] ?? 'Usuario';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: obtenerNombreUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // O un spinner pequeño
        }
        if (snapshot.hasError) {
          return const Text(
            'Error al cargar el nombre',
            style: TextStyle(color: Colors.white),
          );
        }

        return Text(
          'Bienvenid@, ${snapshot.data}!',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
