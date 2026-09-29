import 'package:flutter/material.dart';

import '../data/incidencias_repository.dart';
import '../models/incidencia.dart';
import '../theme/app_colors.dart';

class PanelVerificadorScreen extends StatefulWidget {
  const PanelVerificadorScreen({super.key});

  @override
  State<PanelVerificadorScreen> createState() => _PanelVerificadorScreenState();
}

class _PanelVerificadorScreenState extends State<PanelVerificadorScreen> {
  late Future<List<Incidencia>> _pendientes;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _pendientes = IncidenciasRepository.instance.pendientes();
  }

  Future<void> _resolver(Incidencia incidencia, EstadoIncidencia nuevoEstado) async {
    await IncidenciasRepository.instance.cambiarEstado(incidencia.id, nuevoEstado);
    setState(_cargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes pendientes'), centerTitle: true),
      body: FutureBuilder<List<Incidencia>>(
        future: _pendientes,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pendientes = snapshot.data!;
          if (pendientes.isEmpty) {
            return Center(
              child: Text(
                'No hay reportes pendientes de revisión.',
                style: TextStyle(color: AppColors.grisTexto),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendientes.length,
            itemBuilder: (context, i) {
              final incidencia = pendientes[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(incidencia.tipo.icono, color: incidencia.colorEstado),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              incidencia.tipo.etiqueta,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Text(
                            '${incidencia.confirmaciones} confirmaciones',
                            style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
                          ),
                        ],
                      ),
                      if (incidencia.comentario?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(incidencia.comentario!),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Reportado por ${incidencia.reportadoPor}',
                        style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _resolver(incidencia, EstadoIncidencia.descartado),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Descartar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resolver(incidencia, EstadoIncidencia.verificado),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Verificar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
