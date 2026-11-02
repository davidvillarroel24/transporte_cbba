import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Vista de cámara en vivo usada como fondo de la navegación asistida.
/// Maneja el ciclo de vida de la app (pausa la cámara cuando la app pasa a
/// segundo plano), el caso sin cámara disponible, y errores nativos que
/// pueden aparecer después de inicializar (algunos teléfonos con la
/// implementación "legacy" de la cámara Android fallan en el primer
/// intento de abrir la sesión; acá se puede reintentar).
class CamaraFondo extends StatefulWidget {
  const CamaraFondo({super.key});

  @override
  State<CamaraFondo> createState() => _CamaraFondoState();
}

class _CamaraFondoState extends State<CamaraFondo> with WidgetsBindingObserver {
  CameraController? _controlador;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Se difiere al siguiente frame para asegurar que el motor de Flutter
    // ya haya registrado la superficie de textura antes de que la cámara
    // intente usarla (evita una carrera que en algunos dispositivos deja
    // la vista previa en negro).
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
  }

  Future<void> _inicializar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'Este dispositivo no tiene una cámara disponible.';
            _cargando = false;
          });
        }
        return;
      }
      final trasera = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );
      final anterior = _controlador;
      _controlador = null;
      await anterior?.dispose();

      final controlador = CameraController(
        trasera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      controlador.addListener(_alCambiarEstado);
      await controlador.initialize();
      if (!mounted) {
        await controlador.dispose();
        return;
      }
      setState(() {
        _controlador = controlador;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo abrir la cámara. Probá de nuevo.';
          _cargando = false;
        });
      }
    }
  }

  void _alCambiarEstado() {
    final controlador = _controlador;
    if (controlador == null) return;
    if (controlador.value.hasError && mounted) {
      setState(() {
        _error = 'La cámara se desconectó. Probá de nuevo.';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    final controlador = _controlador;
    if (controlador == null || !controlador.value.isInitialized) return;
    if (estado == AppLifecycleState.inactive || estado == AppLifecycleState.paused) {
      controlador.removeListener(_alCambiarEstado);
      controlador.dispose();
      _controlador = null;
    } else if (estado == AppLifecycleState.resumed) {
      _inicializar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador?.removeListener(_alCambiarEstado);
    _controlador?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlador = _controlador;
    if (_error != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _inicializar,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final previewSize = controlador?.value.previewSize;
    if (_cargando || controlador == null || !controlador.value.isInitialized || previewSize == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controlador),
        ),
      ),
    );
  }
}
