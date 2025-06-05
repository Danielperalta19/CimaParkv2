import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'widgets/boton_regresar_widget.dart';

class GestionarUsuariosPage extends StatelessWidget {
  const GestionarUsuariosPage({super.key});

  Future<void> eliminarUsuario(String userId, DocumentReference tipoRef) async {
    try {
      // Paso 1 y 2: obtener datos del alumno
      final tipoSnapshot = await tipoRef.get();
      final tipoData = tipoSnapshot.data() as Map<String, dynamic>? ?? {};

      // Paso 3: obtener referencia al vehículo (si existe)
      if (tipoData.containsKey('vehiculo_ref') &&
          tipoData['vehiculo_ref'] is DocumentReference) {
        final vehiculoRef = tipoData['vehiculo_ref'] as DocumentReference;

        // Paso 4: eliminar el vehículo
        await vehiculoRef.delete();
      }

      // Paso 5: eliminar el documento del alumno
      await tipoRef.delete();

      // Paso 6: eliminar el documento del usuario
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .delete();

      print('Usuario, alumno y vehículo eliminados exitosamente.');
    } catch (e) {
      print('Error al eliminar usuario: $e');
    }
  }

  void _mostrarDialogoEditarUsuario(
    BuildContext context,
    DocumentSnapshot user,
  ) async {
    String tipoUsuario = user['tipo_usuario'];
    final tipoRef = user['tipo_ref'] as DocumentReference;

    final tipoSnapshot = await tipoRef.get();
    final data = tipoSnapshot.data() as Map<String, dynamic>? ?? {};

    final nombreController = TextEditingController(text: data['nombre'] ?? '');
    final apellido1Controller = TextEditingController(
      text: data['primer_apellido'] ?? '',
    );
    final apellido2Controller = TextEditingController(
      text: data['segundo_apellido'] ?? '',
    );
    final matriculaController = TextEditingController(
      text: data['matricula'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar datos personales', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apellido1Controller,
                decoration: InputDecoration(
                  labelText: 'Primer Apellido',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apellido2Controller,
                decoration: InputDecoration(
                  labelText: 'Segundo Apellido',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: matriculaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Matrícula',
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
              // Validaciones
              if (nombreController.text.trim().isEmpty ||
                  apellido1Controller.text.trim().isEmpty ||
                  matriculaController.text.trim().isEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Center(
                      heightFactor: 1,
                      child: Text(
                        'Por favor, completa todos los campos obligatorios',
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
              if (!RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(nombreController.text.trim()) ||
                  !RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(apellido1Controller.text.trim()) ||
                  (apellido2Controller.text.trim().isNotEmpty &&
                   !RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(apellido2Controller.text.trim()))) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Center(
                      heightFactor: 1,
                      child: Text(
                        'Los nombres solo pueden contener letras y espacios',
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
              if (!RegExp(r'^\d+$').hasMatch(matriculaController.text.trim())) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Center(
                      heightFactor: 1,
                      child: Text(
                        'La matrícula debe contener solo números',
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
              await tipoRef.update({
                'nombre': nombreController.text.trim(),
                'primer_apellido': apellido1Controller.text.trim(),
                'segundo_apellido': apellido2Controller.text.trim(),
                'matricula': matriculaController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Center(
                    heightFactor: 1,
                    child: Text(
                      'Usuario actualizado con éxito',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                  margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  duration: Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
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
                // Logo centrado en la parte superior
                Center(child: Image.asset('assets/logo.png', height: 80)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24, bottom: 8),
                    child: FloatingActionButton(
                      heroTag: 'fab_usuario',
                      mini: true,
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, '/agregar_usuario');
                      },
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('usuarios')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final user = docs[index];
                          final uid = user.id;
                          final correo = user['correo'] ?? '';
                          final tipoRef = user['tipo_ref'] as DocumentReference;

                          return FutureBuilder<DocumentSnapshot>(
                            future: tipoRef.get(),
                            builder: (context, tipoSnapshot) {
                              String matricula = '';
                              if (tipoSnapshot.hasData && tipoSnapshot.data != null) {
                                final tipoData = tipoSnapshot.data!.data() as Map<String, dynamic>?;
                                matricula = tipoData?['matricula'] ?? '';
                              }
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                                            correo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Matrícula: $matricula',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _mostrarDialogoEditarUsuario(
                                          context,
                                          user,
                                        );
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
                                              'Eliminar usuario',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: const Text(
                                              '¿Estás seguro que deseas eliminar este usuario?',
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
                                          try {
                                            await eliminarUsuario(uid, tipoRef);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Center(
                                                  heightFactor: 1,
                                                  child: Text(
                                                    'Usuario eliminado con éxito',
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                backgroundColor: Colors.green,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                                                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                duration: Duration(seconds: 2),
                                                elevation: 8,
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Center(
                                                  heightFactor: 1,
                                                  child: Text(
                                                    'Error al eliminar usuario',
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
                                          }
                                        }
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
