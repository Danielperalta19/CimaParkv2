import 'package:flutter/material.dart';

class HomeCimapark extends StatelessWidget {
  const HomeCimapark({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Image.asset(
            'assets/fondo.jpeg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          // Contenido principal
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/logo.png', height: 300),
                  SizedBox(height: 60),

                  // Botón Ingresar
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 70,
                        vertical: 25,
                      ),
                    ),
                    child: Text('Ingresar', style: TextStyle(fontSize: 30)),
                  ),
                  SizedBox(height: 20),

                  // Botón Crear cuenta
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/registro');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 25,
                      ),
                    ),
                    child: Text('Crear cuenta', style: TextStyle(fontSize: 30)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
