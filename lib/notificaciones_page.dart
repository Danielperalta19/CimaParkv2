import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/boton_regresar_widget.dart';

class NotificacionesPage extends StatelessWidget {
  const NotificacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificacionesRef = FirebaseFirestore.instance.collection(
      'notificaciones',
    );
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fondo.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(child: Image.asset('assets/logo.png', height: 100)),
                const SizedBox(height: 10),
                const Text(
                  'Notificaciones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        notificacionesRef
                            .orderBy('fecha', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      final visibles =
                          docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final List<dynamic> eliminados =
                                data['eliminadoPor'] ?? [];
                            return !eliminados.contains(uid);
                          }).toList();

                      if (visibles.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay notificaciones por ahora.',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: visibles.length,
                        itemBuilder: (context, index) {
                          final doc = visibles[index];
                          final data = doc.data() as Map<String, dynamic>;

                          // Marcar como vista si no está
                          final List<dynamic> vistos = data['vistoPor'] ?? [];
                          if (!vistos.contains(uid)) {
                            doc.reference.update({
                              'vistoPor': FieldValue.arrayUnion([uid]),
                            });
                          }

                          return Dismissible(
                            key: Key(doc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              alignment: Alignment.centerRight,
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) async {
                              await doc.reference.update({
                                'eliminadoPor': FieldValue.arrayUnion([uid]),
                              });
                            },
                            child: Card(
                              color: Colors.white.withOpacity(0.9),
                              child: ListTile(
                                leading: const Icon(Icons.notifications),
                                title: Text(data['titulo'] ?? 'Sin título'),
                                subtitle: Text(data['contenido'] ?? ''),
                              ),
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

          // Botón de regresar
          const Positioned(
            top: 40,
            left: 20,
            child: BotonRegresar(),
          ),
        ],
      ),
    );
  }
}
