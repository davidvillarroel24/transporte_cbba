/// Franjas horarias de congestión vehicular por ingreso/salida escolar
/// (ver PDF de requerimientos): 07:00, 14:00 y 19:00, 45 minutos cada una.
/// Es una estimación referencial fija, no una medición de tráfico real.
const _horariosCongestion = [
  (hora: 7, minuto: 0),
  (hora: 14, minuto: 0),
  (hora: 19, minuto: 0),
];

const _duracionCongestionMinutos = 45;

/// true si [ahora] cae dentro de alguna de las franjas de congestión.
bool hayCongestionActiva(DateTime ahora) {
  for (final horario in _horariosCongestion) {
    final inicio = DateTime(ahora.year, ahora.month, ahora.day, horario.hora, horario.minuto);
    final fin = inicio.add(const Duration(minutes: _duracionCongestionMinutos));
    if (!ahora.isBefore(inicio) && ahora.isBefore(fin)) return true;
  }
  return false;
}
