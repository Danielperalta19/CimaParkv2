import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'widgets/boton_regresar_widget.dart';
import 'widgets/boton_notificaciones_widget.dart';
import 'notificaciones_page.dart';

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

  Future<String?> _pedirPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Verificación'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Ingresa tu contraseña actual',
              ),
              obscureText: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Confirmar'),
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
              obscureText: campo == 'Contraseña',
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final usuarios = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid);
      final usuarioDoc = await usuarios.get();
      final tipoRef = usuarioDoc.data()?['tipo_ref'] as DocumentReference?;

      if (tipoRef == null) return;

      // Solo reautenticar si va a modificar correo o contraseña
      if (campo == 'Correo' || campo == 'Contraseña') {
        final passwordActual =
            await _pedirPassword(); // pedir contraseña actual

        if (passwordActual == null || passwordActual.isEmpty) return;

        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordActual,
        );

        await user.reauthenticateWithCredential(cred);
      }

      switch (campo) {
        case 'Nombre completo':
          await tipoRef.update({'nombre': nuevoValor});
          setState(() => nombre = nuevoValor);
          break;

        case 'Correo':
          await user.updateEmail(nuevoValor); // Firebase Auth
          await usuarios.update({'correo': nuevoValor}); // Firestore
          setState(() => correo = nuevoValor);
          break;

        case 'Contraseña':
          await user.updatePassword(nuevoValor); // Firebase Auth
          await usuarios.update({
            'password': nuevoValor,
          }); // (⚠️ evita guardar contraseñas planas en Firestore)
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
    } catch (e) {
      print('🚨 Error al actualizar campo $campo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar $campo. Vuelve a intentarlo'),
        ),
      );
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No estás autenticado')));
    }
    final uid = user.uid;

    // Editar datos personales
    void mostrarDialogoEditarDatos(Map<String, dynamic> alumnoData, DocumentReference alumnoRef, VoidCallback onSuccess) {
      final nombreController = TextEditingController(text: alumnoData['nombre'] ?? '');
      final primerApellidoController = TextEditingController(text: alumnoData['primer_apellido'] ?? '');
      final segundoApellidoController = TextEditingController(text: alumnoData['segundo_apellido'] ?? '');
      final matriculaController = TextEditingController(text: alumnoData['matricula'] ?? '');

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
                  controller: primerApellidoController,
                  decoration: InputDecoration(
                    labelText: 'Primer Apellido',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: segundoApellidoController,
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
                try {
                  // Validar que todos los campos estén llenos
                  if (nombreController.text.trim().isEmpty ||
                      primerApellidoController.text.trim().isEmpty ||
                      matriculaController.text.trim().isEmpty) {
                    throw Exception('Por favor, completa todos los campos obligatorios');
                  }

                  // Validar formato de nombres (solo letras y espacios)
                  if (!RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(nombreController.text.trim()) ||
                      !RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(primerApellidoController.text.trim()) ||
                      (segundoApellidoController.text.trim().isNotEmpty && 
                       !RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(segundoApellidoController.text.trim()))) {
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

                  // Validar formato de matrícula (solo números)
                  if (!RegExp(r'^\d+$').hasMatch(matriculaController.text.trim())) {
                    throw Exception('La matrícula debe contener solo números');
                  }

                  await alumnoRef.update({
                    'nombre': nombreController.text.trim(),
                    'primer_apellido': primerApellidoController.text.trim(),
                    'segundo_apellido': segundoApellidoController.text.trim(),
                    'matricula': matriculaController.text.trim(),
                  });
                  Navigator.pop(context);
                  onSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Datos actualizados correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Cambiar correo
    void mostrarDialogoCambiarCorreo(String correoActual, DocumentReference usuarioRef) {
      final correoController = TextEditingController(text: correoActual);
      final passwordController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cambiar correo', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: correoController,
                decoration: InputDecoration(
                  labelText: 'Nuevo correo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
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
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) throw 'No autenticado';
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: passwordController.text.trim(),
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.updateEmail(correoController.text.trim());
                  await usuarioRef.update({'correo': correoController.text.trim()});
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo actualizado correctamente'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Cambiar contraseña
    void mostrarDialogoCambiarContrasena(DocumentReference usuarioRef) {
      final actualController = TextEditingController();
      final nuevaController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cambiar contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: actualController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nuevaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
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
                final nueva = nuevaController.text.trim();
                if (nueva.length < 6) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Center(
                        heightFactor: 1,
                        child: Text(
                          'La contraseña debe tener al menos 6 caracteres.',
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
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) throw 'No autenticado';
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: actualController.text.trim(),
                  );
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(nueva);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contraseña actualizada correctamente'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Editar vehículo
    void mostrarDialogoEditarVehiculo(Map<String, dynamic> vehiculoData, DocumentReference vehiculoRef, VoidCallback onSuccess) {
      final placasController = TextEditingController(text: vehiculoData['placas'] ?? '');
      String? marcaSeleccionada = vehiculoData['marca'];
      String? modeloSeleccionado = vehiculoData['modelo'];
      String? colorSeleccionado = vehiculoData['color'];
      int? anioSeleccionado = vehiculoData['anio'];

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

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Editar vehículo', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    marcaSeleccionada = value;
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
                    modeloSeleccionado = value;
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
                    anioSeleccionado = value;
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
                    colorSeleccionado = value;
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
                try {
                  // Validar que todos los campos estén llenos
                  if (marcaSeleccionada == null ||
                      modeloSeleccionado == null ||
                      colorSeleccionado == null ||
                      anioSeleccionado == null ||
                      placasController.text.trim().isEmpty) {
                    throw Exception('Por favor, completa todos los campos');
                  }

                  // Validar formato de placas (solo letras y números)
                  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(placasController.text.trim())) {
                    throw Exception('Las placas solo pueden contener letras y números');
                  }

                  // Verificar si el año seleccionado es válido
                  final anioActual = DateTime.now().year;
                  if (anioSeleccionado! > anioActual) {
                    throw Exception('El año del vehículo no puede ser mayor al año actual');
                  }

                  await vehiculoRef.update({
                    'marca': marcaSeleccionada,
                    'modelo': modeloSeleccionado,
                    'color': colorSeleccionado,
                    'placas': placasController.text.trim(),
                    'anio': anioSeleccionado,
                  });
                  Navigator.pop(context);
                  onSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vehículo actualizado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
        builder: (context, usuarioSnap) {
          if (!usuarioSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!usuarioSnap.data!.exists) {
            return const Center(child: Text('Usuario no encontrado'));
          }
          final usuarioData = usuarioSnap.data!.data() as Map<String, dynamic>?;
          if (usuarioData == null) {
            return const Center(child: Text('Datos de usuario no disponibles'));
          }

          final correo = usuarioData['correo'] ?? '';
          final tipoUsuario = usuarioData['tipo_usuario'] ?? '';
          final tipoRef = usuarioData['tipo_ref'];

          if (tipoRef == null || tipoRef is! DocumentReference) {
            return const Center(child: Text('Referencia a alumno no disponible'));
          }

          return FutureBuilder<DocumentSnapshot>(
            future: tipoRef.get(),
            builder: (context, alumnoSnap) {
              if (!alumnoSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!alumnoSnap.data!.exists) {
                return const Center(child: Text('Alumno no encontrado'));
              }
              final alumnoData = alumnoSnap.data!.data() as Map<String, dynamic>?;
              if (alumnoData == null) {
                return const Center(child: Text('Datos de alumno no disponibles'));
              }

              final nombre = alumnoData['nombre'] ?? '';
              final primerApellido = alumnoData['primer_apellido'] ?? '';
              final segundoApellido = alumnoData['segundo_apellido'] ?? '';
              final matricula = alumnoData['matricula'] ?? '';
              final vehiculoRef = alumnoData['vehiculo_ref'];

              return FutureBuilder<DocumentSnapshot?>(
                future: (vehiculoRef is DocumentReference) ? vehiculoRef.get() : Future.value(null),
                builder: (context, vehiculoSnap) {
                  final vehiculoData = (vehiculoSnap.hasData && vehiculoSnap.data != null && vehiculoSnap.data!.exists)
                      ? vehiculoSnap.data!.data() as Map<String, dynamic>?
                      : null;

                  String nombreCompleto = nombre;
                  if (primerApellido.isNotEmpty) nombreCompleto += ' $primerApellido';
                  if (segundoApellido.isNotEmpty) nombreCompleto += ' $segundoApellido';

                  String vehiculoStr = 'Sin vehículo registrado';
                  if (vehiculoData != null) {
                    vehiculoStr = '${vehiculoData['marca'] ?? ''} ${vehiculoData['modelo'] ?? ''} ${vehiculoData['color'] ?? ''} ${vehiculoData['anio'] ?? ''}, Placas: ${vehiculoData['placas'] ?? ''}';
                  }

                  return Stack(
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
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                                const SizedBox(height: 30),
                                // Logo centrado
                                Center(child: Image.asset('assets/logo.png', height: 100)),
                    const SizedBox(height: 20),
                                // Avatar y botón editar
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.green[200],
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(Icons.account_circle, size: 100, color: Colors.black54),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            mostrarDialogoEditarDatos(
                                              alumnoData,
                                              alumnoSnap.data!.reference,
                                              () => setState(() {}),
                                            );
                                          },
                                          child: const CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.white,
                                            child: Icon(Icons.edit, size: 18, color: Colors.green),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  nombreCompleto,
                                  style: const TextStyle(
                                    fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                // Correo
                                const Text(
                                  'Correo:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  correo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                // Matrícula
                                const Text(
                                  'Matrícula:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  matricula,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                // Contraseña
                                const Text(
                                  'Contraseña:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '********',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white),
                                      tooltip: 'Cambiar contraseña',
                                      onPressed: () {
                                        mostrarDialogoCambiarContrasena(usuarioSnap.data!.reference);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                // Vehículo
                                const Text(
                                  'Vehículo:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (vehiculoData != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          vehiculoStr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Padding(
                                        padding: EdgeInsets.only(right: 16),
                                        child: IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white),
                                          tooltip: 'Editar vehículo',
                                          onPressed: () {
                                            mostrarDialogoEditarVehiculo(
                                              vehiculoData,
                                              vehiculoSnap.data!.reference,
                                              () => setState(() {}),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      const Text(
                                        'Debes registrar un vehículo para usar la app.',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        icon: const Icon(Icons.directions_car),
                                        label: const Text('Registrar vehículo'),
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/vehiculos');
                                        },
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 18),
                                // Botón de cerrar sesión
                                ElevatedButton.icon(
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.logout),
                                  label: const Text(
                                    'Cerrar sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
                      const Positioned(
                        top: 40,
                        left: 20,
                        child: BotonRegresar(),
                      ),
                      // Botón de notificaciones
                      BotonCampanita(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificacionesPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
            '$label: ',
                  style: const TextStyle(
              color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            ),
        ],
      ),
    );
  }
}
