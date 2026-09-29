import 'package:flutter/material.dart';

import '../data/incidencias_repository.dart';
import '../models/incidencia.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Abre el formulario para reportar el estado de una calle en el punto
/// del mapa que el usuario marcó. Devuelve true si se guardó el reporte.
Future<bool?> mostrarReportarIncidencia(
  BuildContext context, {
  required double lat,
  required double lon,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _FormularioIncidencia(lat: lat, lon: lon),
  );
}

class _FormularioIncidencia extends StatefulWidget {
  final double lat;
  final double lon;

  const _FormularioIncidencia({required this.lat, required this.lon});

  @override
  State<_FormularioIncidencia> createState() => _FormularioIncidenciaState();
}

class _FormularioIncidenciaState extends State<_FormularioIncidencia> {
  TipoIncidencia? _tipoSeleccionado;
  final _controladorComentario = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _controladorComentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final tipo = _tipoSeleccionado;
    final usuario = AuthService.instance.usuarioActual;
    if (tipo == null || usuario == null) return;
    setState(() => _enviando = true);
    await IncidenciasRepository.instance.crear(
      tipo: tipo,
      lat: widget.lat,
      lon: widget.lon,
      comentario: _controladorComentario.text.trim().isEmpty
          ? null
          : _controladorComentario.text.trim(),
      usuarioId: usuario.id,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportar el estado de esta calle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu reporte quedará marcado como información no verificada, '
            'aportada por usuarios, hasta que un verificador la revise.',
            style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TipoIncidencia.values.map((tipo) {
              final seleccionado = tipo == _tipoSeleccionado;
              return ChoiceChip(
                label: Text(tipo.etiqueta),
                avatar: Icon(tipo.icono, size: 18),
                selected: seleccionado,
                onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controladorComentario,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Comentario opcional (ej. desde qué hora, qué tan grave es)',
              filled: true,
              fillColor: AppColors.grisFondo,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_tipoSeleccionado == null || _enviando) ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar reporte'),
            ),
          ),
        ],
      ),
    );
  }
}
