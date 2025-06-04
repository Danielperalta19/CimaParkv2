/* eslint-disable max-len */


const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

exports.eliminarUsuarioCompleto = functions.https.onCall(async (data, context) => {
  const uid = data.uid;

  if (!uid) {
    throw new functions.https.HttpsError("invalid-argument", "El UID es obligatorio.");
  }

  try {
    // Buscar usuario en la colección 'usuarios'
    const usuariosSnap = await db.collection("usuarios").where("uid", "==", uid).get();
    if (usuariosSnap.empty) {
      throw new functions.https.HttpsError("not-found", "Usuario no encontrado en Firestore.");
    }

    const usuarioDoc = usuariosSnap.docs[0];
    const usuarioData = usuarioDoc.data();

    // Verificar tipo_usuario
    if (usuarioData.tipo_usuario !== "alumno") {
      throw new functions.https.HttpsError("failed-precondition", "Solo se puede eliminar a alumnos con esta función.");
    }

    // Obtener referencia al documento de alumno
    const alumnoRef = usuarioData.tipo_ref;
    const alumnoDoc = await alumnoRef.get();

    if (alumnoDoc.exists) {
      const alumnoData = alumnoDoc.data();

      // Eliminar vehículo si está registrado
      if (alumnoData.vehiculo_ref) {
        const vehiculoRef = alumnoData.vehiculo_ref;
        await vehiculoRef.delete();
      }

      // Eliminar documento del alumno
      await alumnoRef.delete();
    }

    // Eliminar documento del usuario
    await usuarioDoc.ref.delete();

    // Eliminar usuario de Firebase Auth
    await auth.deleteUser(uid);

    return {message: "Usuario, alumno y vehículo eliminados exitosamente."};
  } catch (error) {
    console.error("Error al eliminar usuario:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
