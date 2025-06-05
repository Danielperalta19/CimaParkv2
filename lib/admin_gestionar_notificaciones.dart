import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/boton_regresar_widget.dart';

class GestionarNotificacionesPage extends StatelessWidget {
  const GestionarNotificacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificacionesRef = FirebaseFirestore.instance.collection(
      'notificaciones',
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fondo.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(child: Image.asset('assets/logo.png', height: 80)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24, bottom: 8),
                    child: FloatingActionButton(
                      heroTag: 'fab_noti',
                      mini: true,
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      onPressed: () => _mostrarFormularioNotificacion(context, null),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gestionar Notificaciones',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: notificacionesRef.orderBy('fecha', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final noti = docs[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        noti['titulo'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        noti['contenido'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _mostrarFormularioNotificacion(context, noti);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: const Text(
                                          'Eliminar notificación',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: const Text(
                                          '¿Estás seguro que deseas eliminar esta notificación?',
                                          style: TextStyle(color: Colors.black87),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      FirebaseFirestore.instance.collection('notificaciones').doc(noti.id).delete();
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 40,
            left: 20,
            child: BotonRegresar(),
          ),
        ],
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          notificacion != null ? 'Editar Notificación' : 'Nueva Notificación',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contenidoController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Contenido',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final titulo = tituloController.text.trim();
              final contenido = contenidoController.text.trim();

              if (titulo.isEmpty || contenido.isEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Center(
                      heightFactor: 1,
                      child: Text(
                        'Por favor, completa todos los campos',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    duration: Duration(seconds: 2),
                    elevation: 8,
                  ),
                );
                return;
              }

              final ref = FirebaseFirestore.instance.collection('notificaciones');
              if (notificacion == null) {
                await ref.add({
                  'titulo': titulo,
                  'contenido': contenido,
                  'fecha': DateTime.now(),
                  'vistoPor': [],
                });
              } else {
                await ref.doc(notificacion.id).update({
                  'titulo': titulo,
                  'contenido': contenido,
                });
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Center(
                    heightFactor: 1,
                    child: Text(
                      notificacion == null
                          ? 'Notificación creada con éxito'
                          : 'Notificación actualizada con éxito',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  duration: const Duration(seconds: 2),
                  elevation: 8,
                ),
              );
            },
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
