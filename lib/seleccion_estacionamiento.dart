import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/boton_regresar_widget.dart';

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
        transaction.update(userRef, {
          'estacionado': true,
          'estacionamiento_actual':
              docId, // Guardamos el estacionamiento actual
        });
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

      final userData = userSnapshot.data();
      if (userSnapshot.exists && userData?['estacionado'] == false) {
        throw Exception('No estás estacionado en ningún espacio');
      }

      // Aquí validamos que esté saliendo del mismo estacionamiento
      if (userData?['estacionamiento_actual'] != docId) {
        throw Exception('No estás estacionado en este estacionamiento');
      }

      final disponibles = estacionamientoSnapshot['lugares_restantes'];
      final capacidad = estacionamientoSnapshot['capacidad'];

      if (disponibles < capacidad) {
        transaction.update(userRef, {
          'estacionado': false,
          'estacionamiento_actual': FieldValue.delete(), // Limpiamos el campo
        });
        transaction.update(docRef, {'lugares_restantes': disponibles + 1});
      } else {
        throw Exception('No hay espacios ocupados para liberar');
      }
    });
  }

  // Helper function for custom SnackBar
  void mostrarSnackBar(BuildContext context, String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          heightFactor: 1,
          child: Text(
            mensaje,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: const Duration(seconds: 2),
        elevation: 8,
      ),
    );
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
      stream: FirebaseFirestore.instance.collection('usuarios').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final bool isEstacionado = userData?['estacionado'] == true;

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

            if (!snapshot.data!.exists) {
              return const Scaffold(
                body: Center(
                  child: Text('Estacionamiento no encontrado'),
                ),
              );
            }

            final estacionamiento = snapshot.data!;
            final data = estacionamiento.data() as Map<String, dynamic>?;
            
            if (data == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Datos del estacionamiento no disponibles'),
                ),
              );
            }

            final nombre = data['nombre'] as String? ?? 'Sin nombre';
            final disponibles = data['lugares_restantes'] as int? ?? 0;
            final capacidad = data['capacidad'] as int? ?? 0;

            // Lógica de color dinámica según disponibilidad
            Color colorSegunDisponibilidad(int restantes, int total) {
              if (total == 0) return Colors.grey.withOpacity(0.5);
              double porcentaje = restantes / total;
              if (porcentaje >= 0.6) {
                return Colors.green.withOpacity(0.55);
              } else if (porcentaje >= 0.3) {
                return Colors.yellow.withOpacity(0.55);
              } else {
                return Colors.red.withOpacity(0.55);
              }
            }
            final overlayColor = colorSegunDisponibilidad(disponibles, capacidad);

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
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const SizedBox(height: 40),
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
                          Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              height: 350,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Imagen de fondo
                                  Image.asset(
                                    'assets/zoom_${nombre}.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text('Imagen no disponible', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Overlay de color cuadrado con borde blanco y nombre centrado
                                  Center(
                                    child: Container(
                                      width: 240,
                                      height: 240,
                                      decoration: BoxDecoration(
                                        color: overlayColor,
                                        borderRadius: BorderRadius.circular(32),
                                        border: Border.all(color: Colors.white, width: 6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontSize: 100,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 2,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(2, 2),
                                              blurRadius: 8,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              'Espacios disponibles: $disponibles / $capacidad',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: Text(
                              'Estás:',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 64),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isEstacionado ? Colors.grey[400] : const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: isEstacionado
                                      ? null
                                      : () async {
                                          try {
                                            await marcarEstacionado(docId, userId);
                                            mostrarSnackBar(context, '¡Te estacionaste!', Colors.green);
                                          } catch (e) {
                                            mostrarSnackBar(context, e.toString(), Colors.red);
                                          }
                                        },
                                  child: const Text(
                                    'Estacionado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !isEstacionado ? Colors.grey[400] : const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 2,
                                  ),
                                  onPressed: !isEstacionado
                                      ? null
                                      : () async {
                                          try {
                                            await marcarSaliendo(docId, userId);
                                            mostrarSnackBar(context, '¡Se liberó tu espacio!', Colors.green);
                                          } catch (e) {
                                            String errorMsg = e.toString();
                                            if (errorMsg.contains('No estás estacionado en ningún espacio')) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('No estás estacionado'),
                                                  content: const Text('No puedes salir porque no estás estacionado en ningún espacio.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Aceptar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else if (errorMsg.contains('Dart exception thrown from converted Future')) {
                                              mostrarSnackBar(context, 'Estás estacionado en otro estacionamiento.', Colors.red);
                                            } else {
                                              print('Error inesperado en saliendo:');
                                              print(errorMsg);
                                              mostrarSnackBar(context, 'Ocurrió un error inesperado. Intenta de nuevo.', Colors.red);
                                            }
                                          }
                                        },
                                  child: const Text(
                                    'Saliendo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
          },
        );
      },
    );
  }
}
