import 'package:flutter/material.dart';

import '../data/congestion_escolar_repository.dart';
import '../data/gtfs_repository.dart';
import '../data/lineas_admin_repository.dart';
import '../data/tarifas_repository.dart';
import '../data/usuarios_repository.dart';
import '../models/colegio_congestion.dart';
import '../models/linea.dart';
import '../models/parada.dart';
import '../models/tarifa_pasajero.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'elegir_punto_mapa_screen.dart';

class PanelAdminScreen extends StatefulWidget {
  const PanelAdminScreen({super.key});

  @override
  State<PanelAdminScreen> createState() => _PanelAdminScreenState();
}

class _PanelAdminScreenState extends State<PanelAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Usuarios'),
            Tab(text: 'Líneas'),
            Tab(text: 'Congestión'),
            Tab(text: 'Tarifas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_TabUsuarios(), _TabLineas(), _TabCongestion(), _TabTarifas()],
      ),
    );
  }
}

class _TabUsuarios extends StatefulWidget {
  const _TabUsuarios();

  @override
  State<_TabUsuarios> createState() => _TabUsuariosState();
}

class _TabUsuariosState extends State<_TabUsuarios> {
  late Future<List<Usuario>> _usuarios;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _usuarios = UsuariosRepository.instance.listarTodos();
  }

  Future<void> _cambiarRol(Usuario usuario, RolUsuario nuevoRol) async {
    await UsuariosRepository.instance.cambiarRol(usuario.id, nuevoRol);
    if (usuario.id == AuthService.instance.usuarioActual?.id) {
      await AuthService.instance.refrescarSesion();
    }
    setState(_cargar);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>>(
      future: _usuarios,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final usuarios = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: usuarios.length,
          separatorBuilder: (context, i) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final usuario = usuarios[i];
            return Card(
              child: ListTile(
                title: Text(usuario.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(usuario.email, style: TextStyle(color: AppColors.grisTexto)),
                trailing: DropdownButton<RolUsuario>(
                  value: usuario.rol,
                  underline: const SizedBox(),
                  onChanged: usuario.email == 'admin@transporte.com'
                      ? null
                      : (nuevo) {
                          if (nuevo != null) _cambiarRol(usuario, nuevo);
                        },
                  items: RolUsuario.values.map((rol) {
                    return DropdownMenuItem(
                      value: rol,
                      child: Text(Usuario(id: '', nombre: '', email: '', rol: rol).rolTexto),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TabLineas extends StatefulWidget {
  const _TabLineas();

  @override
  State<_TabLineas> createState() => _TabLineasState();
}

class _TabLineasState extends State<_TabLineas> {
  late Future<List<Linea>> _lineas;
  final _controladorBusqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _lineas = GtfsRepository.instance.todasLasLineas();
  }

  Future<void> _editar(Linea linea) async {
    final controladorNombre = TextEditingController(text: linea.nombreCorto);
    var activa = true;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar línea'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controladorNombre,
                decoration: const InputDecoration(labelText: 'Distintivo / nombre corto'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Línea activa'),
                value: activa,
                onChanged: (v) => setDialogState(() => activa = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (resultado == true) {
      await LineasAdminRepository.instance.guardar(
        rutaId: linea.id,
        nombreCorto: controladorNombre.text.trim(),
        activa: activa,
      );
      setState(_cargar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controladorBusqueda,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar línea por distintivo',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.blanco,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Linea>>(
            future: _lineas,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final filtro = _controladorBusqueda.text.trim().toLowerCase();
              final lineas = snapshot.data!
                  .where((l) => filtro.isEmpty || l.nombreCorto.toLowerCase().contains(filtro))
                  .toList();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: lineas.length,
                itemBuilder: (context, i) {
                  final linea = lineas[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: linea.color, radius: 14),
                      title: Text(linea.nombreCorto),
                      subtitle: linea.nombreLargo.isEmpty ? null : Text(linea.nombreLargo),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _editar(linea),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TabCongestion extends StatefulWidget {
  const _TabCongestion();

  @override
  State<_TabCongestion> createState() => _TabCongestionState();
}

class _TabCongestionState extends State<_TabCongestion> {
  late Future<List<ColegioCongestion>> _colegios;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _colegios = CongestionEscolarRepository.instance.listarTodos();
  }

  Future<void> _agregar() async {
    final punto = await Navigator.push<Parada>(
      context,
      MaterialPageRoute(
        builder: (context) => const ElegirPuntoMapaScreen(
          titulo: 'Marca el colegio en el mapa',
        ),
      ),
    );
    if (punto == null || !mounted) return;
    final datos = await _dialogoDatos(nombreInicial: punto.nombre);
    if (datos == null) return;
    await CongestionEscolarRepository.instance.agregar(
      nombre: datos.$1,
      calle: datos.$2,
      lat: punto.lat,
      lon: punto.lon,
    );
    setState(_cargar);
  }

  Future<void> _editar(ColegioCongestion colegio) async {
    final datos = await _dialogoDatos(nombreInicial: colegio.nombre, calleInicial: colegio.calle);
    if (datos == null) return;
    await CongestionEscolarRepository.instance.editar(
      id: colegio.id,
      nombre: datos.$1,
      calle: datos.$2,
    );
    setState(_cargar);
  }

  Future<void> _eliminar(ColegioCongestion colegio) async {
    await CongestionEscolarRepository.instance.eliminar(colegio.id);
    setState(_cargar);
  }

  Future<(String, String?)?> _dialogoDatos({String? nombreInicial, String? calleInicial}) async {
    final controladorNombre = TextEditingController(text: nombreInicial ?? '');
    final controladorCalle = TextEditingController(text: calleInicial ?? '');
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Colegio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controladorNombre,
              decoration: const InputDecoration(labelText: 'Nombre del colegio'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controladorCalle,
              decoration: const InputDecoration(labelText: 'Calle o avenida (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (resultado != true || controladorNombre.text.trim().isEmpty) return null;
    final calle = controladorCalle.text.trim();
    return (controladorNombre.text.trim(), calle.isEmpty ? null : calle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<ColegioCongestion>>(
        future: _colegios,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final colegios = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: colegios.length,
            itemBuilder: (context, i) {
              final colegio = colegios[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                  title: Text(colegio.nombre),
                  subtitle: colegio.calle == null ? null : Text(colegio.calle!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editar(colegio),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _eliminar(colegio),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregar,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Agregar'),
      ),
    );
  }
}

class _TabTarifas extends StatefulWidget {
  const _TabTarifas();

  @override
  State<_TabTarifas> createState() => _TabTarifasState();
}

class _TabTarifasState extends State<_TabTarifas> {
  late Future<List<TarifaPasajero>> _tarifas;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _tarifas = TarifasRepository.instance.listarTodas();
  }

  Future<void> _editarPrecio(TarifaPasajero tarifa) async {
    final controlador = TextEditingController(text: tarifa.precio.toStringAsFixed(2));
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tarifa: ${tarifa.tipo}'),
        content: TextField(
          controller: controlador,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'Bs ', labelText: 'Precio'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (resultado != true) return;
    final precio = double.tryParse(controlador.text.trim().replaceAll(',', '.'));
    if (precio == null) return;
    await TarifasRepository.instance.actualizarPrecio(tarifa.tipo, precio);
    setState(_cargar);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TarifaPasajero>>(
      future: _tarifas,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final tarifas = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tarifas.length,
          separatorBuilder: (context, i) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final tarifa = tarifas[i];
            return Card(
              child: ListTile(
                title: Text(tarifa.tipo),
                trailing: Text(
                  'Bs ${tarifa.precio.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => _editarPrecio(tarifa),
              ),
            );
          },
        );
      },
    );
  }
}
