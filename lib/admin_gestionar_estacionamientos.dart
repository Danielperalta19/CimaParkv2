import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'formulario_estacionamiento.dart';

class GestionarEstacionamientosPage extends StatelessWidget {
  const GestionarEstacionamientosPage({super.key});

  Future<void> eliminarEstacionamiento(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('estacionamientos')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error al eliminar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Estacionamientos')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('estacionamientos')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final estacionamientos = snapshot.data!.docs;

          if (estacionamientos.isEmpty) {
            return const Center(
              child: Text('No hay estacionamientos registrados.'),
            );
          }

          return ListView.builder(
            itemCount: estacionamientos.length,
            itemBuilder: (context, index) {
              final estacionamiento = estacionamientos[index];
              final data = estacionamiento.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['nombre'] ?? 'Sin nombre'),
                  subtitle: Text(
                    'Capacidad: ${data['capacidad']} | Disponibles: ${data['lugares_restantes']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FormularioEstacionamiento(
                                    estacionamiento: estacionamiento,
                                  ),
                            ),
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Confirmar eliminación'),
                                  content: const Text(
                                    '¿Estás seguro de eliminar este estacionamiento?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            await eliminarEstacionamiento(estacionamiento.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormularioEstacionamiento(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
