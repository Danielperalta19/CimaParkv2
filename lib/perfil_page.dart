import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  String nombre = '';
  String correo = '';
  String matricula = '';
  String vehiculo = '';
  String password = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final usuarioDoc =
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .get();

        final usuarioData = usuarioDoc.data();
        if (usuarioData != null) {
          correo = usuarioData['correo'] ?? '';
          password = usuarioData['password'] ?? '';
          final refAlumno = usuarioData['tipo_ref'] as DocumentReference;

          final alumnoDoc = await refAlumno.get();
          final alumnoData = alumnoDoc.data() as Map<String, dynamic>?;

          if (alumnoData != null) {
            nombre = alumnoData['nombre'] ?? '';
            matricula = alumnoData['matricula'] ?? '';

            // ✅ Leer la referencia al vehículo desde el alumno
            if (alumnoData.containsKey('vehiculo_ref')) {
              final vehiculoRef =
                  alumnoData['vehiculo_ref'] as DocumentReference;
              final vehiculoDoc = await vehiculoRef.get();
              final vehiculoData = vehiculoDoc.data() as Map<String, dynamic>?;

              if (vehiculoData != null) {
                // Puedes concatenar marca + modelo o mostrar solo placas, etc.
                vehiculo =
                    '${vehiculoData['marca']} ${vehiculoData['modelo']} - ${vehiculoData['placas']}';

                print('Vehículo recuperado: $vehiculo');
              }
            }
          }

          // Mostrar alerta si no hay vehículo registrado
          if (vehiculo.trim().isEmpty) {
            Future.delayed(Duration.zero, _mostrarAlertaVehiculo);
          }

          setState(() {});
        }
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
    }
  }

  void _mostrarAlertaVehiculo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.red.withOpacity(
              0.8,
            ), // 🔴 Rojo semi-transparente
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                16,
              ), // Esquinas redondeadas (opcional)
            ),
            title: const Text(
              'Vehículo no registrado',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Por favor, registra un vehículo para poder continuar usando la app.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: Colors.white),
                ),
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
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fondo.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Logo arriba a la izquierda
          Positioned(
            top: 20,
            left: 20,
            child: Image.asset('assets/logo.png', width: 200, height: 200),
          ),

          // Contenido principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20), // Separación del logo
                    const Text(
                      'Mi Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField('Nombre completo', nombre),
                    _buildField('Correo', correo),
                    _buildField('Contraseña', '********'),
                    _buildField('Matrícula', matricula),
                    _buildField('Vehículo', vehiculo),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    final bool esVehiculo = label == 'Vehículo';
    final bool mostrarBoton = esVehiculo && value.trim().isEmpty;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value.trim().isNotEmpty ? value : 'Sin registrar',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              if (mostrarBoton)
                TextButton(
                  onPressed: () {
                    // 🔁 Cambia esta ruta según tu app
                    Navigator.pushNamed(context, '/vehiculos');
                  },
                  child: const Text(
                    'Registrar',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
