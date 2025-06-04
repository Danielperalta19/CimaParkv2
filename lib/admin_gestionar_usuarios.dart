import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    final correoController = TextEditingController(text: user['correo']);
    final passwordController = TextEditingController(
      text: user['password'] ?? '',
    );
    String tipoUsuario = user['tipo_usuario'];
    final tipoRef = user['tipo_ref'] as DocumentReference;

    // Obtenemos los datos del documento referenciado (admin o alumno)
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Datos del usuario"),
                TextField(
                  controller: correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                DropdownButtonFormField<String>(
                  value: tipoUsuario,
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'alumno', child: Text('Alumno')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      tipoUsuario = value;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tipo de usuario',
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Datos personales"),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: apellido1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Primer Apellido',
                  ),
                ),
                TextField(
                  controller: apellido2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Segundo Apellido',
                  ),
                ),
                TextField(
                  controller: matriculaController,
                  decoration: const InputDecoration(labelText: 'Matrícula'),
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
              onPressed: () async {
                // Actualizar documento en la colección usuarios
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user.id)
                    .update({
                      'correo': correoController.text.trim(),
                      'password': passwordController.text.trim(),
                      'tipo_usuario': tipoUsuario,
                    });

                // Actualizar documento referenciado (admin o alumno)
                await tipoRef.update({
                  'nombre': nombreController.text.trim(),
                  'primer_apellido': apellido1Controller.text.trim(),
                  'segundo_apellido': apellido2Controller.text.trim(),
                  'matricula': matriculaController.text.trim(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario actualizado con éxito'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Image.asset('assets/logo.png', width: 200),

                  const SizedBox(height: 16),
                  const Text(
                    'Gestionar Usuarios',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                            final tipo = user['tipo_usuario'] ?? '';

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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          correo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Tipo: $tipo',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          _mostrarDialogoEditarUsuario(
                                            context,
                                            user,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          // Eliminar usuario (tu código original)
                                          showDialog(
                                            context: context,
                                            builder: (
                                              BuildContext dialogContext,
                                            ) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Eliminar usuario',
                                                ),
                                                content: const Text(
                                                  '¿Estás seguro de que deseas eliminar este usuario?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                    child: const Text(
                                                      'Cancelar',
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                    onPressed: () async {
                                                      final tipoRef =
                                                          user['tipo_ref']
                                                              as DocumentReference;
                                                      await eliminarUsuario(
                                                        user.id,
                                                        tipoRef,
                                                      );
                                                      Navigator.pop(
                                                        dialogContext,
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Usuario eliminado con éxito',
                                                          ),
                                                          backgroundColor:
                                                              Colors.green,
                                                          duration: Duration(
                                                            seconds: 2,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text(
                                                      'Eliminar',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/agregar_usuario');
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.person_add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
