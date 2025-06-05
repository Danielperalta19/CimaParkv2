import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/boton_regresar_widget.dart';

class FormularioEstacionamiento extends StatefulWidget {
  final DocumentSnapshot? estacionamiento;

  const FormularioEstacionamiento({super.key, this.estacionamiento});

  @override
  State<FormularioEstacionamiento> createState() =>
      _FormularioEstacionamientoState();
}

class _FormularioEstacionamientoState extends State<FormularioEstacionamiento> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _capacidadController = TextEditingController();
  final TextEditingController _lugaresController = TextEditingController();
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.estacionamiento != null) {
      final data = widget.estacionamiento!.data() as Map<String, dynamic>;
      _nombreController.text = data['nombre'] ?? '';
      _capacidadController.text = '${data['capacidad'] ?? ''}';
      _lugaresController.text = '${data['lugares_restantes'] ?? ''}';
      _xController.text = '${data['x'] ?? ''}';
      _yController.text = '${data['y'] ?? ''}';
    }
  }

  Future<void> guardarEstacionamiento() async {
    if (!_formKey.currentState!.validate()) return;

    final capacidad = int.tryParse(_capacidadController.text) ?? 0;
    final disponibles = int.tryParse(_lugaresController.text) ?? 0;
    final x = double.tryParse(_xController.text) ?? 0.0;
    final y = double.tryParse(_yController.text) ?? 0.0;

    // Validar que los lugares disponibles no excedan la capacidad
    if (disponibles > capacidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los lugares disponibles no pueden exceder la capacidad'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que las coordenadas estén dentro del mapa
    if (x < 0 || x > 400 || y < 0 || y > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las coordenadas deben estar dentro del mapa (X: 0-400, Y: 0-500)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'nombre': _nombreController.text.trim(),
      'capacidad': capacidad,
      'lugares_restantes': disponibles,
      'x': x,
      'y': y,
    };

    try {
      if (widget.estacionamiento == null) {
        await FirebaseFirestore.instance
            .collection('estacionamientos')
            .add(data);
      } else {
        await widget.estacionamiento!.reference.update(data);
      }
      // No se regresa automáticamente, el usuario debe usar el botón de regresar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estacionamiento guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al guardar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el estacionamiento'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              child: Stack(
                children: [
                  // Botón de regresar estilo app
                  Positioned(
                    left: 16,
                    child: BotonRegresar(),
                  ),
                  // Logo centrado y pequeño
                  Center(
                    child: Image.asset('assets/logo.png', height: 80),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Crea un estacionamiento',
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

                    // Formulario para crear/editar estacionamiento
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nombreController,
                              decoration: InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _capacidadController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Capacidad',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                final n = int.tryParse(value ?? '');
                                if (n == null || n <= 0) return 'Ingresa una capacidad válida';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _lugaresController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Lugares disponibles',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                final n = int.tryParse(value ?? '');
                                final cap = int.tryParse(_capacidadController.text);
                                if (n == null || n < 0) return 'Ingresa un número válido';
                                if (cap != null && n > cap) return 'No puede ser mayor que la capacidad';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _xController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Coordenada X',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa X' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _yController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Coordenada Y',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa Y' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: guardarEstacionamiento,
                              child: Text(widget.estacionamiento == null ? 'Crear estacionamiento' : 'Guardar cambios', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
