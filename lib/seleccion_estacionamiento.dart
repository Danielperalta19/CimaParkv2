import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetalleEstacionamientoPage extends StatelessWidget {
  const DetalleEstacionamientoPage({super.key});

  Future<void> marcarEstacionado(String docId, String userId) async {
    final docRef = FirebaseFirestore.instance
        .collection('estacionamientos')
        .doc(docId);
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Obtener el documento del usuario y el estacionamiento
      final userSnapshot = await transaction.get(userRef);
      final estacionamientoSnapshot = await transaction.get(docRef);

      // Verificar si el usuario ya está estacionado
      if (userSnapshot.exists && userSnapshot.data()!['estacionado'] == true) {
        throw Exception('Ya estás estacionado en un espacio');
      }

      // Verificar si hay lugares disponibles
      final disponibles = estacionamientoSnapshot['lugares_restantes'];
      if (disponibles > 0) {
        // Si hay lugares disponibles, marcar al usuario como estacionado
        transaction.update(userRef, {'estacionado': true});

        // Reducir los lugares disponibles en el estacionamiento
        transaction.update(docRef, {'lugares_restantes': disponibles - 1});
      } else {
        throw Exception('No hay espacios disponibles');
      }
    });
  }

  Future<void> marcarSaliendo(String docId, String userId) async {
    final docRef = FirebaseFirestore.instance
        .collection('estacionamientos')
        .doc(docId);
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Obtener el documento del usuario y el estacionamiento
      final userSnapshot = await transaction.get(userRef);
      final estacionamientoSnapshot = await transaction.get(docRef);

      // Verificar si el usuario está estacionado
      if (userSnapshot.exists && userSnapshot.data()!['estacionado'] == false) {
        throw Exception('No estás estacionado en ningún espacio');
      }

      // Obtener los valores de espacios disponibles y capacidad
      final disponibles = estacionamientoSnapshot['lugares_restantes'];
      final capacidad = estacionamientoSnapshot['capacidad'];

      // Verificar si el espacio no está lleno antes de liberar un espacio
      if (disponibles < capacidad) {
        // Si hay un espacio ocupado, liberar el espacio
        transaction.update(userRef, {'estacionado': false});

        // Incrementar los lugares disponibles en el estacionamiento
        transaction.update(docRef, {'lugares_restantes': disponibles + 1});
      } else {
        throw Exception('No hay espacios ocupados para liberar');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final docId = ModalRoute.of(context)!.settings.arguments as String;

    // Obtener el userId del usuario autenticado
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Si no hay un usuario autenticado, redirigir a la página de inicio de sesión
      return const Scaffold(body: Center(child: Text('No estás autenticado')));
    }
    final userId = user.uid;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('estacionamientos')
              .doc(docId)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final estacionamiento = snapshot.data!;
        final nombre = estacionamiento['nombre'];
        final disponibles = estacionamiento['lugares_restantes'];
        final capacidad = estacionamiento['capacidad'];

        return Scaffold(
          appBar: AppBar(title: Text(nombre)),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Image.asset(
                  'assets/mapa_estacionamientos_zoom.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Espacios disponibles: $disponibles / $capacidad',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              const Text('Estás:', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await marcarEstacionado(docId, userId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Te estacionaste!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    child: const Text('Estacionado'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await marcarSaliendo(docId, userId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '¡Se liberó tu espacio de estacionamiento!',
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    child: const Text('Saliendo'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
