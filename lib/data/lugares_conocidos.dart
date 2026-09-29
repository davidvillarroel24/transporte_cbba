/// Atractivos turísticos reales de Cochabamba usados como accesos rápidos
/// en "Favoritos". Sus coordenadas son las del lugar real; la parada de
/// transporte más cercana se busca en el GTFS en tiempo de ejecución
/// (nunca se inventa una línea o parada para estos lugares).
class LugarConocido {
  final String nombre;
  final String direccion;
  final double lat;
  final double lon;

  const LugarConocido({
    required this.nombre,
    required this.direccion,
    required this.lat,
    required this.lon,
  });
}

const lugaresConocidos = <LugarConocido>[
  LugarConocido(
    nombre: 'Cristo de la Concordia',
    direccion: 'Cerro San Pedro, mirador y teleférico',
    lat: -17.3961,
    lon: -66.1447,
  ),
  LugarConocido(
    nombre: 'Plaza 14 de Septiembre',
    direccion: 'Plaza principal, centro histórico',
    lat: -17.3936,
    lon: -66.1570,
  ),
  LugarConocido(
    nombre: 'Palacio Portales',
    direccion: 'Zona Queru Queru, ex residencia de Simón Patiño',
    lat: -17.3765,
    lon: -66.1466,
  ),
  LugarConocido(
    nombre: 'Convento Santa Teresa',
    direccion: 'Museo de arte colonial, centro histórico',
    lat: -17.3927,
    lon: -66.1547,
  ),
  LugarConocido(
    nombre: 'Mercado La Cancha',
    direccion: 'Av. Pulacayo, el mercado más grande de Bolivia',
    lat: -17.3993,
    lon: -66.1567,
  ),
];
