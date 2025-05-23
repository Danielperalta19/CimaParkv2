import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionarVehiculosPage extends StatelessWidget {
  const GestionarVehiculosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vehiculosRef = FirebaseFirestore.instance.collection('vehiculos');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Vehículos'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: vehiculosRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final vehiculo = docs[index];

              return FutureBuilder<QuerySnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('alumnos')
                        .where('vehiculo_ref', isEqualTo: vehiculo.reference)
                        .limit(1)
                        .get(),
                builder: (context, snapshot) {
                  String nombreUsuario = 'Sin asignar';

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final usuario = snapshot.data!.docs.first;
                    nombreUsuario = usuario['nombre'];
                  }

                  return ListTile(
                    title: Text(
                      '${vehiculo['modelo']} - ${vehiculo['placas']}',
                    ),
                    subtitle: Text(
                      'Color: ${vehiculo['color']} \nAlumno: $nombreUsuario',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () {
                            _mostrarFormularioVehiculo(context, vehiculo);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // Opcional: buscar usuarios y quitar el vínculo antes de borrar
                            final usuariosSnap =
                                await FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .where(
                                      'vehiculo_ref',
                                      isEqualTo: vehiculo.reference,
                                    )
                                    .get();

                            for (var usuario in usuariosSnap.docs) {
                              await usuario.reference.update({
                                'vehiculo_ref': null,
                              });
                            }

                            await vehiculo.reference.delete();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _mostrarFormularioVehiculo(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarFormularioVehiculo(
    BuildContext context,
    DocumentSnapshot? vehiculo,
  ) {
    final placaController = TextEditingController(text: vehiculo?['placa']);
    final modeloController = TextEditingController(text: vehiculo?['modelo']);
    final colorController = TextEditingController(text: vehiculo?['color']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(vehiculo != null ? 'Editar Vehículo' : 'Nuevo Vehículo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: placaController,
                decoration: const InputDecoration(labelText: 'Placa'),
              ),
              TextField(
                controller: modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final placa = placaController.text.trim();
                final modelo = modeloController.text.trim();
                final color = colorController.text.trim();

                if (placa.isEmpty || modelo.isEmpty || color.isEmpty) return;

                final data = {'placa': placa, 'modelo': modelo, 'color': color};

                final ref = FirebaseFirestore.instance.collection('vehiculos');
                if (vehiculo == null) {
                  await ref.add(data);
                } else {
                  await ref.doc(vehiculo.id).update(data);
                }

                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
