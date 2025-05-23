import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    final data = {
      'nombre': _nombreController.text.trim(),
      'capacidad': int.tryParse(_capacidadController.text) ?? 0,
      'lugares_restantes': int.tryParse(_lugaresController.text) ?? 0,
      'x': double.tryParse(_xController.text) ?? 0.0,
      'y': double.tryParse(_yController.text) ?? 0.0,
    };

    try {
      if (widget.estacionamiento == null) {
        await FirebaseFirestore.instance
            .collection('estacionamientos')
            .add(data);
      } else {
        await widget.estacionamiento!.reference.update(data);
      }
      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.estacionamiento == null
              ? 'Agregar Estacionamiento'
              : 'Editar Estacionamiento',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator:
                    (value) => value!.isEmpty ? 'Ingresa un nombre' : null,
              ),
              TextFormField(
                controller: _capacidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacidad'),
              ),
              TextFormField(
                controller: _lugaresController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lugares disponibles',
                ),
              ),
              TextFormField(
                controller: _xController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Coordenada X'),
              ),
              TextFormField(
                controller: _yController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Coordenada Y'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: guardarEstacionamiento,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
