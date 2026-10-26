# Maestrito — Transporte público de Cochabamba

Aplicación móvil (Flutter) para consultar líneas, rutas, horarios y tarifas del transporte público urbano de Cochabamba, con mapa en vivo, búsqueda de ruta por origen/destino, favoritos, roles de usuario, y reportes colaborativos sobre el estado de las calles.

## Arquitectura de datos

El proyecto usa **dos bases de datos con responsabilidades distintas**:

- **SQLite (local, en el teléfono)** — guarda el catálogo GTFS importado de Cochabamba: líneas, paradas, horarios, trazados de rutas y tarifas. Son datos de solo lectura, pesados (decenas de miles de registros) y no necesitan sincronizarse entre usuarios, así que viven offline en el dispositivo. Ver `lib/data/gtfs_importer.dart` y `lib/data/app_database.dart`.
- **Firebase (Firestore + Authentication, plan gratuito Spark)** — guarda todo lo dinámico y compartido entre usuarios: cuentas, roles (usuario / verificador / admin), favoritos personales, reportes de incidencias en las calles y sus confirmaciones, y reportes de congestión. Esto necesita estar en la nube porque, a diferencia del catálogo GTFS, tiene sentido solo si lo que reporta un usuario lo puede ver otro usuario en otro teléfono.

  El plan Spark de Firebase es gratuito y alcanza de sobra para este proyecto: Firestore permite 50 000 lecturas, 20 000 escrituras y 20 000 eliminaciones por día, con 1 GiB de almacenamiento; Authentication es gratis hasta 50 000 usuarios activos al mes. No requiere tarjeta de crédito.

  > Estado actual: el código de autenticación y roles (`lib/services/auth_service.dart`, `lib/data/usuarios_repository.dart`, `lib/data/favoritos_repository.dart`, `lib/data/incidencias_repository.dart`) todavía usa SQLite local como un primer MVP de un solo dispositivo. La migración a Firestore está diseñada pero pendiente de implementar (ver estimado de costo más abajo).

## Interfaz de navegación asistida por cámara (planificado)

En vez de realidad aumentada completa (seguimiento 3D del entorno vía ARCore, que depende de hardware certificado y de un plugin de comunidad poco mantenido), se optó por un enfoque más simple y liviano: una cámara en vivo con indicadores 2D superpuestos, calculados a partir del GPS y los sensores del teléfono. Piezas del diseño:

- **Cámara en vivo** como fondo (paquete `camera`, oficial de Flutter) — no ARCore.
- **Pin del punto de abordaje**: crece o se achica según la distancia restante. Visible solo si se cumplen *ambas* condiciones: distancia ≤ 20 m **y** la diferencia entre el rumbo hacia el destino y hacia dónde apunta el teléfono está dentro del campo de visión de la cámara (~60-65°). Tamaño máximo: 1/5 del alto de pantalla. Botón para mostrarlo/ocultarlo manualmente.
- **Brújula y minimapa** en esquinas de la pantalla, colapsables a una barra delgada arriba con un botón (para no recargar la vista, estilo HUD de videojuego).
- **Detección de orientación del teléfono** (vertical vs. acostado) con el paquete `sensors_plus`, comparando en qué eje del acelerómetro predomina la gravedad — el overlay solo aparece si el teléfono está "de pie", no sobre una mesa.
- **Aviso de calibración de brújula**, recurrente al entrar a la vista, con botón "no volver a mostrar" (preferencia guardada localmente).
- **Línea de perspectiva** tipo "luces de pista de aterrizaje" hacia el pin, con animación de iluminación secuencial (`CustomPainter` + `AnimationController`).
- **Modo asistente** cuando el destino está fuera del campo de visión de la cámara: línea punteada + mensaje de texto ("girá a la derecha/izquierda" o "está detrás tuyo, date la vuelta"), decidido según en qué sector cae la diferencia de rumbo. Esto reemplaza la necesidad de un motor de ruteo peatonal real (tipo GraphHopper u OSRM), que se descartó por ahora.

**Limitación a tener presente**: esta guía es por rumbo en línea recta, no conoce calles ni obstáculos reales — es un asistente aproximado, no un router peatonal.

## Congestión colaborativa (planificado)

Los usuarios reportan, mediante un formulario, el nivel de congestión percibido (bajo/medio/alto) de un sector en una franja horaria determinada. El nivel "oficial" que se muestra en el mapa se calcula por consenso: el nivel más reportado/confirmado entre los usuarios gana — mismo principio de confiabilidad por cantidad de reportes que ya usan los reportes de incidencias de calles. Se reutiliza el mismo patrón de formulario y repositorio ya construido para incidencias.

## Estimado de costo (trabajo pendiente)

| Paquete | Estimado |
|---|---|
| Interfaz de navegación asistida por cámara (completa) | 3.4 a 5.5 días |
| Congestión colaborativa | 1 a 1.5 días |
| Migración de SQLite a Firebase para datos compartidos (configurar proyecto, `flutterfire configure`, reescribir repositorios y reglas de seguridad, probar sincronización entre dos dispositivos) | 1 a 2 días |
| **Total** | **5.9 a 9 días** |

Es considerablemente menos que la alternativa con ARCore real, que por sí sola ya rondaba 4-6 días con mayor riesgo técnico (plugin no oficial, solo Android, pruebas que requieren dispositivo físico) y sin resolver la sincronización entre dispositivos.

## Desarrollo

Proyecto Flutter estándar:

```
flutter pub get
flutter run
```

Al implementarse Firebase, hará falta además:

```
flutterfire configure
```

para generar `firebase_options.dart` y vincular el proyecto con una cuenta de Firebase (gratuita).

## Estructura del proyecto

- `lib/data/` — acceso a datos: importador y repositorio del GTFS, base de datos local.
- `lib/models/` — modelos de dominio (Parada, Linea, Usuario, Incidencia, Favorito, etc.).
- `lib/services/` — servicios transversales (ubicación, autenticación).
- `lib/screens/` — pantallas de la app.
- `lib/widgets/` — componentes reutilizables.
- `assets/cochabamba_gtfs/` — feed GTFS público de Cochabamba (Trufi Association) usado como fuente de datos real de líneas, paradas y horarios.
