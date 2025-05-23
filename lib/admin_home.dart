import 'package:flutter/material.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fondo.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(
              context,
              icon: Icons.group,
              label: 'Gestionar Usuarios',
              color: Colors.blue,
              onTap: () {
                // TODO: Navegar a gestión de cuentas de usuario
              },
            ),
            _buildCard(
              context,
              icon: Icons.local_parking,
              label: 'Gestionar Estacionamientos',
              color: Colors.green,
              onTap: () {
                // TODO: Navegar a edición de espacios
              },
            ),
            _buildCard(
              context,
              icon: Icons.notifications,
              label: 'Gestionar Notificaciones',
              color: Colors.orange,
              onTap: () {
                // TODO: Navegar a notificaciones
              },
            ),
            _buildCard(
              context,
              icon: Icons.directions_car,
              label: 'Gestionar Vehículos',
              color: Colors.red,
              onTap: () {
                // TODO: Navegar a vehículos
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
