import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cimaparkv2/widgets/nombre_usuario_widget.dart';
import 'package:cimaparkv2/perfil_page.dart';
import 'package:cimaparkv2/notificaciones_page.dart';

class MapaEstacionamientosPage extends StatefulWidget {
  const MapaEstacionamientosPage({super.key});

  @override
  State<MapaEstacionamientosPage> createState() =>
      _MapaEstacionamientosPageState();
}

class _MapaEstacionamientosPageState extends State<MapaEstacionamientosPage> {
  bool hayNotificaciones = false;

  @override
  void initState() {
    super.initState();
    verificarNotificaciones();
  }

  Future<void> verificarNotificaciones() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('notificaciones')
            .orderBy('fecha', descending: true)
            .get();

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> vistos = (data.containsKey('vistoPor') && data['vistoPor'] != null)
        ? List<dynamic>.from(data['vistoPor'])
        : [];
      if (!vistos.contains(uid)) {
        setState(() {
          hayNotificaciones = true;
        });
        return;
      }
    }

    setState(() {
      hayNotificaciones = false;
    });
  }

  // Función para definir color según disponibilidad
  Color _colorSegunDisponibilidad(int restantes, int total) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fondo.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Encabezado
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Image.asset('assets/logo.png', height: 100),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: NombreUsuarioWidget(),
                  ),
                ],
              ),
            ),

            // Cuerpo
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                children: [
                  const Text(
                    'Selecciona un estacionamiento',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Mapa
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      width: 400,
                      height: 500,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/mapa.png',
                              fit: BoxFit.cover,
                              width: 400,
                              height: 500,
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('estacionamientos')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay estacionamientos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }

                              final docs = snapshot.data!.docs;

                              return Stack(
                                children:
                                    docs.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final posX = (data['x'] ?? 0).toDouble();
                                      final posY = (data['y'] ?? 0).toDouble();
                                      final nombre =
                                          data['nombre'] ?? 'Estacionamiento';
                                      final lugaresRestantes =
                                          data['lugares_restantes'] ?? 0;
                                      final capacidadTotal =
                                          data['capacidad'] ?? 1;
                                      final docId = doc.id;

                                      return Positioned(
                                        left: posX,
                                        top: posY,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/detalle_estacionamiento',
                                              arguments: docId,
                                            );
                                          },
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: _colorSegunDisponibilidad(
                                                lugaresRestantes,
                                                capacidadTotal,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              nombre,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Leyenda
                  Flexible(
                    child: Image.asset(
                      'assets/leyenda.png',
                      width: 500,
                      height: 150,
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),

            // Botón campanita
            Positioned(
              bottom: 20,
              left: 20,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('notificaciones')
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  bool mostrarAlerta = false;

                  if (snapshot.hasData && uid != null) {
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final List<dynamic> vistos = (data.containsKey('vistoPor') && data['vistoPor'] != null)
                        ? List<dynamic>.from(data['vistoPor'])
                        : [];
                      if (!vistos.contains(uid)) {
                        mostrarAlerta = true;
                        break;
                      }
                    }
                  }

                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      FloatingActionButton(
                        heroTag: 'notificaciones',
                        backgroundColor: Colors.green,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificacionesPage(),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                      ),
                      if (mostrarAlerta)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Botón de perfil
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.green[800],
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PerfilPage()),
                  );
                },
                child: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Ir a Perfil',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
