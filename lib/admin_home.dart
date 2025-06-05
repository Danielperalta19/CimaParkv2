import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_gestionar_usuarios.dart';
import 'admin_gestionar_estacionamientos.dart';
import 'admin_gestionar_notificaciones.dart';
import 'admin_gestionar_vehiculos.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String? adminName;

  @override
  void initState() {
    super.initState();
    _loadAdminNameFromReference();
  }

  Future<void> _loadAdminNameFromReference() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();

      if (usuarioDoc.exists) {
        final ref = usuarioDoc['tipo_ref'] as DocumentReference;

        final adminDoc = await ref.get();
        if (adminDoc.exists) {
          setState(() {
            adminName = adminDoc['nombre'];
          });
        }
      }
    } catch (e) {
      print('Error cargando nombre del admin: $e');
    }
  }

  Future<void> _cerrarSesion() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo de imagen
          Positioned.fill(
            child: Image.asset(
              'assets/fondo.jpeg', // Asegúrate de tener esta imagen en assets
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                // Logo en la esquina superior izquierda
                Positioned(
                  top: 16,
                  left: 16,
                  child: Image.asset(
                    'assets/logo.png', // Reemplaza con tu logo
                    width: 200,
                  ),
                ),

                // Texto de bienvenida en la esquina superior derecha
                Positioned(
                  top: 24,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      adminName != null
                          ? 'Bienvenid@, $adminName!'
                          : 'Cargando...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Botones centrales
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPanelButton('Gestionar Usuarios', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const GestionarUsuariosPage(),
                              ),
                            );
                          }),

                          _buildPanelButton('Gestionar Estacionamientos', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const GestionarEstacionamientosPage(),
                              ),
                            );
                          }),

                          _buildPanelButton('Gestionar Notificaciones', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const GestionarNotificacionesPage(),
                              ),
                            );
                          }),

                          _buildPanelButton('Gestionar Vehículos', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const GestionarVehiculosPage(),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botón de cerrar sesión en la parte inferior izquierda
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: FloatingActionButton(
                    heroTag: 'logout_admin',
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            '¿Estás seguro que deseas cerrar sesión?',
                            style: TextStyle(color: Colors.black87),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _cerrarSesion();
                              },
                              child: const Text('Cerrar sesión'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Icon(Icons.logout),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white, // <- aquí lo corriges
            ),
          ),
        ),
      ),
    );
  }
}
