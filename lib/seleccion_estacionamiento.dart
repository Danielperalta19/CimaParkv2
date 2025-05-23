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
      final userSnapshot = await transaction.get(userRef);
      final estacionamientoSnapshot = await transaction.get(docRef);

      if (userSnapshot.exists && userSnapshot.data()!['estacionado'] == true) {
        throw Exception('Ya estás estacionado en un espacio');
      }

      final disponibles = estacionamientoSnapshot['lugares_restantes'];
      if (disponibles > 0) {
        transaction.update(userRef, {'estacionado': true});
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
      final userSnapshot = await transaction.get(userRef);
      final estacionamientoSnapshot = await transaction.get(docRef);

      if (userSnapshot.exists && userSnapshot.data()!['estacionado'] == false) {
        throw Exception('No estás estacionado en ningún espacio');
      }

      final disponibles = estacionamientoSnapshot['lugares_restantes'];
      final capacidad = estacionamientoSnapshot['capacidad'];

      if (disponibles < capacidad) {
        transaction.update(userRef, {'estacionado': false});
        transaction.update(docRef, {'lugares_restantes': disponibles + 1});
      } else {
        throw Exception('No hay espacios ocupados para liberar');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final docId = ModalRoute.of(context)!.settings.arguments as String;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No estás autenticado')));
    }

    final userId = user.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('estacionamientos')
              .doc(docId)
              .snapshots(),
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
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fondo.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: Image.asset('assets/logo.png', height: 100)),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
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
                Center(
                  child: Text(
                    'Espacios disponibles: $disponibles / $capacidad',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'Estás:',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
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
                              content: Text('¡Se liberó tu espacio!'),
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
          ),
        );
      },
    );
  }
}
