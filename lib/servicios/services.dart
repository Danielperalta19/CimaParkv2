import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

// 3. Obtener todos los usuarios
Future<void> obtenerUsuarios() async {
  final snapshot = await db.collection('usuarios').get();
  for (var doc in snapshot.docs) {
    print('ID: ${doc.id}, Datos: ${doc.data()}');
  }
}

// 4. Obtener un usuario específico por ID
Future<void> obtenerUsuario(String id) async {
  final doc = await db.collection('usuarios').doc(id).get();
  if (doc.exists) {
    print('Usuario: ${doc.data()}');
  } else {
    print('Usuario no encontrado');
  }
}

// 5. Crear un usuario
Future<void> crearUsuario() async {
  await db.collection('usuarios').add({
    'correo': 'ejemplo@correo.com',
    'password': 'abc123',
    'tipo_usuario': 'alumno',
    'tipo_ref': db.doc('/alumnos/VVITVJhdf7YNKwvXUWzl'),
  });
}

// 6. Leer datos desde la referencia
Future<void> leerTipoRef(DocumentReference ref) async {
  final tipoDoc = await ref.get();
  print('Datos del tipo de usuario: ${tipoDoc.data()}');
}

// 7. Obtener usuario y su tipo (alumno/admin)
Future<void> obtenerUsuarioYTipo(String usuarioId) async {
  final usuarioDoc = await db.collection('usuarios').doc(usuarioId).get();
  final usuario = usuarioDoc.data();

  if (usuario != null && usuario['tipo_ref'] != null) {
    final tipoDoc = await (usuario['tipo_ref'] as DocumentReference).get();
    print('Usuario: $usuario');
    print('Tipo (alumno/admin): ${tipoDoc.data()}');
  }
}
