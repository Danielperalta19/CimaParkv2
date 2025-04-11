// alumno_home.dart
import 'package:flutter/material.dart';

class AlumnoHome extends StatelessWidget {
  const AlumnoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Alumno')),
      body: const Center(child: Text('Bienvenido, alumno')),
    );
  }
}
