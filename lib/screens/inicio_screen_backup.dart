import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transporte Cochabamba',
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.directions_bus,
              size: 100,
            ),

            const SizedBox(height: 20),

            const Text(
              'Encuentra tu ruta fácilmente',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {},
              child: const Text(
                'Buscar transporte',
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {},
              child: const Text(
                'Líneas cercanas',
              ),
            ),
          ],
        ),
      ),
    );
  }
}