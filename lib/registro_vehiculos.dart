import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistroVehiculoPage extends StatefulWidget {
  const RegistroVehiculoPage({super.key});

  @override
  State<RegistroVehiculoPage> createState() => _RegistroVehiculoPageState();
}

class _RegistroVehiculoPageState extends State<RegistroVehiculoPage> {
  final _matriculaController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  String? _marcaSeleccionada;
  String? _modeloSeleccionado;
  String? _colorSeleccionado;
  int? _anioSeleccionado;

  final List<String> marcas = ['Toyota', 'Ford', 'Chevrolet'];
  final List<String> modelos = ['Sedán', 'SUV', 'Hatchback'];
  final List<String> colores = ['Rojo', 'Azul', 'Negro', 'Blanco'];

  // Función para generar la lista de años (desde 1900 hasta el año actual)
  List<int> _getAnios() {
    int anioActual = DateTime.now().year;
    return List<int>.generate(
      anioActual - 1990 + 1,
      (index) => anioActual - index,
    );
  }

  Future<void> _registrarVehiculo() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final ahora = DateTime.now();
      final anioActual = ahora.year;

      // Verificar si el año seleccionado es válido
      if (_anioSeleccionado == null || _anioSeleccionado! > anioActual) {
        throw Exception('El año del vehículo no puede ser mayor al año actual');
      }

      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();

      if (!usuarioDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final alumnoRef = usuarioDoc['tipo_ref'] as DocumentReference;
      final alumnoDoc = await alumnoRef.get();
      final alumnoData = alumnoDoc.data() as Map<String, dynamic>?;

      // 🚫 Eliminar vehículo anterior si existe
      if (alumnoData != null && alumnoData['vehiculo_ref'] != null) {
        final viejoVehiculoRef =
            alumnoData['vehiculo_ref'] as DocumentReference;
        await viejoVehiculoRef.delete();
      }

      // ✅ Crear nuevo vehículo
      final nuevoVehiculoRef = await FirebaseFirestore.instance
          .collection('vehiculos')
          .add({
            'marca': _marcaSeleccionada,
            'modelo': _modeloSeleccionado,
            'color': _colorSeleccionado,
            'placas': _matriculaController.text.trim(),
            'anio': _anioSeleccionado,
          });

      // 🔁 Actualizar el alumno con la nueva referencia
      await alumnoRef.update({'vehiculo_ref': nuevoVehiculoRef});

      Navigator.pushReplacementNamed(context, '/estacionamiento');
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items:
          items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/fondo.jpeg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Image.asset('assets/logo.png', height: 200)),
                    const SizedBox(height: 10),

                    const SizedBox(height: 20),
                    const Text(
                      'Placas',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _matriculaController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const Text(
                      'Marca',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    _buildDropdown(
                      'Selecciona la marca',
                      _marcaSeleccionada,
                      marcas,
                      (value) {
                        setState(() => _marcaSeleccionada = value);
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Modelo',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    _buildDropdown(
                      'Selecciona el modelo',
                      _modeloSeleccionado,
                      modelos,
                      (value) {
                        setState(() => _modeloSeleccionado = value);
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Año',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<int>(
                      value: _anioSeleccionado,
                      hint: Text('Selecciona el año'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items:
                          _getAnios().map((int anio) {
                            return DropdownMenuItem<int>(
                              value: anio,
                              child: Text(anio.toString()),
                            );
                          }).toList(),
                      onChanged: (int? value) {
                        setState(() {
                          _anioSeleccionado = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Color',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    _buildDropdown(
                      'Selecciona el color',
                      _colorSeleccionado,
                      colores,
                      (value) {
                        setState(() => _colorSeleccionado = value);
                      },
                    ),

                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Center(
                          child: ElevatedButton(
                            onPressed: _registrarVehiculo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 100,
                                vertical: 20,
                              ),
                            ),
                            child: const Text(
                              'Registrar Vehículo',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),

                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
