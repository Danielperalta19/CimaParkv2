import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BotonCampanita extends StatelessWidget {
  final VoidCallback onTap;

  const BotonCampanita({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('notificaciones')
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildButton(false);
        }

        bool hayNuevas = snapshot.data!.docs.any((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final List<dynamic> vistos = data['vistoPor'] ?? [];
          final List<dynamic> eliminados = data['eliminadoPor'] ?? [];

          return !vistos.contains(uid) && !eliminados.contains(uid);
        });

        return _buildButton(hayNuevas);
      },
    );
  }

  Widget _buildButton(bool hayNuevas) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Stack(
        children: [
          FloatingActionButton(
            heroTag: 'notificaciones_fab',
            backgroundColor: Colors.green,
            onPressed: onTap,
            child: const Icon(Icons.notifications, color: Colors.white),
          ),
          if (hayNuevas)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
