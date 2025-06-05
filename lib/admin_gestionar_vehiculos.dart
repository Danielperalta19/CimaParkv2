import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/boton_regresar_widget.dart';

class GestionarVehiculosPage extends StatelessWidget {
  const GestionarVehiculosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vehiculosRef = FirebaseFirestore.instance.collection('vehiculos');

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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24, bottom: 8),
                    child: FloatingActionButton(
                      heroTag: 'fab_vehiculo',
                      mini: true,
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      onPressed: () => _mostrarFormularioVehiculo(context, null),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vehículos Registrados',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: vehiculosRef.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final vehiculo = docs[index];
                          return FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('alumnos')
                                .where('vehiculo_ref', isEqualTo: vehiculo.reference)
                                .limit(1)
                                .get(),
                            builder: (context, alumnoSnap) {
                              String matricula = '';
                              if (alumnoSnap.hasData && alumnoSnap.data!.docs.isNotEmpty) {
                                final alumno = alumnoSnap.data!.docs.first.data() as Map<String, dynamic>;
                                matricula = alumno['matricula'] ?? '';
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
                                            vehiculo['placas'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Modelo: ${vehiculo['modelo']} | Color: ${vehiculo['color']}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          if (matricula.isNotEmpty)
                                            Text(
                                              'Matrícula: $matricula',
                                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _mostrarFormularioVehiculo(context, vehiculo);
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
                                              'Eliminar vehículo',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: const Text(
                                              '¿Estás seguro que deseas eliminar este vehículo?',
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
                                          FirebaseFirestore.instance.collection('vehiculos').doc(vehiculo.id).delete();
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
          const Positioned(
            top: 40,
            left: 20,
            child: BotonRegresar(),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioVehiculo(
    BuildContext context,
    DocumentSnapshot? vehiculo,
  ) async {
    final placasController = TextEditingController(text: vehiculo?['placas']);
    String? marcaSeleccionada = vehiculo?['marca'];
    String? modeloSeleccionado = vehiculo?['modelo'];
    String? colorSeleccionado = vehiculo?['color'];
    int? anioSeleccionado = vehiculo?['anio'];
    DocumentReference? alumnoSeleccionado;
    List<Map<String, dynamic>> alumnosSinVehiculo = [];

    final List<String> marcas = ['Toyota', 'Ford', 'Chevrolet'];
    final List<String> modelos = ['Sedán', 'SUV', 'Hatchback'];
    final List<String> colores = ['Rojo', 'Azul', 'Negro', 'Blanco'];

    // Función para generar la lista de años (desde 1990 hasta el año actual)
    List<int> getAnios() {
      int anioActual = DateTime.now().year;
      return List<int>.generate(
        anioActual - 1990 + 1,
        (index) => anioActual - index,
      );
    }

    // Verificar si el año actual está en el rango válido
    final anios = getAnios();
    if (anioSeleccionado != null && !anios.contains(anioSeleccionado)) {
      anioSeleccionado = null;
    }

    // Si es nuevo vehículo, obtener alumnos sin vehículo
    if (vehiculo == null) {
      final alumnosSnap = await FirebaseFirestore.instance
          .collection('alumnos')
          .get();
      alumnosSinVehiculo = alumnosSnap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return !data.containsKey('vehiculo_ref') || data['vehiculo_ref'] == null;
      }).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'ref': doc.reference,
          'nombre': data['nombre'] ?? '',
          'primer_apellido': data['primer_apellido'] ?? '',
          'segundo_apellido': data['segundo_apellido'] ?? '',
          'matricula': data['matricula'] ?? '',
        };
      }).toList();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            vehiculo != null ? 'Editar vehículo' : 'Nuevo vehículo',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (vehiculo == null) ...[
                  DropdownButtonFormField<DocumentReference<Object?>>(
                    value: alumnoSeleccionado,
                    hint: const Text('Selecciona un usuario'),
                    decoration: InputDecoration(
                      labelText: 'Asignar a usuario',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    items: alumnosSinVehiculo.map((alumno) {
                      final nombreCompleto =
                        '${alumno['nombre']} ${alumno['primer_apellido']} ${alumno['segundo_apellido']} - ${alumno['matricula']}';
                      return DropdownMenuItem<DocumentReference<Object?>> (
                        value: alumno['ref'] as DocumentReference<Object?>,
                        child: Text(nombreCompleto),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => alumnoSeleccionado = value);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: placasController,
                  decoration: InputDecoration(
                    labelText: 'Placas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: marcaSeleccionada,
                  hint: const Text('Selecciona la marca'),
                  decoration: InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: marcas.map((marca) {
                    return DropdownMenuItem(value: marca, child: Text(marca));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => marcaSeleccionada = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: modeloSeleccionado,
                  hint: const Text('Selecciona el modelo'),
                  decoration: InputDecoration(
                    labelText: 'Modelo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: modelos.map((modelo) {
                    return DropdownMenuItem(value: modelo, child: Text(modelo));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => modeloSeleccionado = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: colorSeleccionado,
                  hint: const Text('Selecciona el color'),
                  decoration: InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: colores.map((color) {
                    return DropdownMenuItem(value: color, child: Text(color));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => colorSeleccionado = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: anioSeleccionado,
                  hint: const Text('Selecciona el año'),
                  decoration: InputDecoration(
                    labelText: 'Año',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: anios.map((anio) {
                    return DropdownMenuItem(value: anio, child: Text(anio.toString()));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => anioSeleccionado = value);
                  },
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
                if (placasController.text.trim().isEmpty ||
                    marcaSeleccionada == null ||
                    modeloSeleccionado == null ||
                    colorSeleccionado == null ||
                    anioSeleccionado == null ||
                    (vehiculo == null && alumnoSeleccionado == null)) {
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
                if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(placasController.text.trim())) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Center(
                        heightFactor: 1,
                        child: Text(
                          'Las placas solo pueden contener letras y números',
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
                final data = {
                  'placas': placasController.text.trim().toUpperCase(),
                  'marca': marcaSeleccionada,
                  'modelo': modeloSeleccionado,
                  'color': colorSeleccionado,
                  'anio': anioSeleccionado,
                };
                final ref = FirebaseFirestore.instance.collection('vehiculos');
                if (vehiculo == null) {
                  final nuevoVehiculo = await ref.add(data);
                  // Asignar referencia al alumno seleccionado
                  await alumnoSeleccionado!.update({'vehiculo_ref': nuevoVehiculo});
                } else {
                  await ref.doc(vehiculo.id).update(data);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Center(
                      heightFactor: 1,
                      child: Text(
                        vehiculo == null
                            ? 'Vehículo registrado con éxito'
                            : 'Vehículo actualizado con éxito',
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
      ),
    );
  }
}
