import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionarNotificacionesPage extends StatelessWidget {
  const GestionarNotificacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificacionesRef = FirebaseFirestore.instance.collection(
      'notificaciones',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Notificaciones'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            notificacionesRef.orderBy('fecha', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final noti = docs[index];
              return ListTile(
                title: Text(noti['titulo']),
                subtitle: Text(noti['contenido']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () {
                        _mostrarFormularioNotificacion(context, noti);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        notificacionesRef.doc(noti.id).delete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _mostrarFormularioNotificacion(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarFormularioNotificacion(
    BuildContext context,
    DocumentSnapshot? notificacion,
  ) {
    final tituloController = TextEditingController(
      text: notificacion?['titulo'],
    );
    final contenidoController = TextEditingController(
      text: notificacion?['contenido'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            notificacion != null ? 'Editar Notificación' : 'Nueva Notificación',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: contenidoController,
                decoration: const InputDecoration(labelText: 'Contenido'),
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
                final titulo = tituloController.text.trim();
                final contenido = contenidoController.text.trim();

                if (titulo.isEmpty || contenido.isEmpty) return;

                final data = {
                  'titulo': titulo,
                  'contenido': contenido,
                  'fecha': DateTime.now(),
                  'activo': true,
                };

                final ref = FirebaseFirestore.instance.collection(
                  'notificaciones',
                );
                if (notificacion == null) {
                  await ref.add(data);
                } else {
                  await ref.doc(notificacion.id).update(data);
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
