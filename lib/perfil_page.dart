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
  String uid = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      uid = user.uid;

      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();

      final usuarioData = usuarioDoc.data();
      if (usuarioData == null) return;

      final correoNuevo = usuarioData['correo'] ?? '';
      final passwordNuevo = usuarioData['password'] ?? '';
      final refAlumno = usuarioData['tipo_ref'] as DocumentReference?;

      if (refAlumno == null) return;

      final alumnoDoc = await refAlumno.get();
      final alumnoData = alumnoDoc.data() as Map<String, dynamic>?;

      if (alumnoData == null) return;

      final nombreNuevo = alumnoData['nombre'] ?? '';
      final matriculaNueva = alumnoData['matricula'] ?? '';

      String vehiculoNuevo = '';
      if (alumnoData.containsKey('vehiculo_ref')) {
        final vehiculoRef = alumnoData['vehiculo_ref'] as DocumentReference?;
        if (vehiculoRef != null) {
          final vehiculoDoc = await vehiculoRef.get();
          final vehiculoData = vehiculoDoc.data() as Map<String, dynamic>?;
          if (vehiculoData != null) {
            vehiculoNuevo =
                '${vehiculoData['marca']} ${vehiculoData['modelo']} - ${vehiculoData['placas']}';
          }
        }
      }

      setState(() {
        correo = correoNuevo;
        password = passwordNuevo;
        nombre = nombreNuevo;
        matricula = matriculaNueva;
        vehiculo = vehiculoNuevo;
      });

      if (vehiculo.trim().isEmpty) {
        Future.delayed(Duration.zero, _mostrarAlertaVehiculo);
      }
    } catch (e, stacktrace) {
      print('🚨 Error al cargar datos del usuario: $e');
      print(stacktrace);
    }
  }

  void _mostrarAlertaVehiculo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.red.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _editarCampo(String campo, String valorActual) async {
    final controller = TextEditingController(text: valorActual);
    final nuevoValor = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Editar $campo'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'Nuevo $campo'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (nuevoValor == null || nuevoValor.trim().isEmpty) return;

    final usuarios = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    final usuarioDoc = await usuarios.get();
    final tipoRef = usuarioDoc.data()?['tipo_ref'] as DocumentReference?;

    if (tipoRef == null) return;

    switch (campo) {
      case 'Nombre completo':
        await tipoRef.update({'nombre': nuevoValor});
        setState(() => nombre = nuevoValor);
        break;
      case 'Correo':
        await usuarios.update({'correo': nuevoValor});
        setState(() => correo = nuevoValor);
        break;
      case 'Contraseña':
        await usuarios.update({'password': nuevoValor});
        setState(() => password = nuevoValor);
        break;
      case 'Matrícula':
        await tipoRef.update({'matricula': nuevoValor});
        setState(() => matricula = nuevoValor);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campo actualizado correctamente')),
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

          // Logo
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
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Mi Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField('Nombre completo', nombre, editable: true),
                    _buildField('Correo', correo, editable: true),
                    _buildField('Contraseña', '********', editable: true),
                    _buildField('Matrícula', matricula, editable: true),
                    _buildField('Vehículo', vehiculo),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, {bool editable = false}) {
    final esVehiculo = label == 'Vehículo';
    final mostrarBoton = esVehiculo && value.trim().isEmpty;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.trim().isNotEmpty ? value : 'Sin registrar',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          if (mostrarBoton)
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/vehiculos');
              },
              child: const Text(
                'Registrar',
                style: TextStyle(color: Colors.blue),
              ),
            )
          else if (editable)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editarCampo(label, value),
            ),
        ],
      ),
    );
  }
}
