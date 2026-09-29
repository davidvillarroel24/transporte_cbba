# Revisión del proyecto "transporte_cochabamba" — Perfil de Grado

**Fecha:** 2026-09-18
**Autor de la revisión:** Sesión de Claude Code (orquestación Padre/Gula/Soberbia/Ira/Pereza)
**Alcance:** (1) cotejo del código Flutter contra los objetivos/alcances del Perfil de Grado; (2) cotejo de las observaciones de la docente (`Docs/Observaciones.txt`) contra el estado actual de `Docs/Perfil de Grado 1.2.docx`; (3) búsqueda y verificación de artículos académicos (DOI, ≤5 años) para respaldar el Marco Teórico; (4) edición directa del Word con las correcciones y la bibliografía APA 7.

> Se hizo una copia de seguridad del documento original antes de editar: `Docs/Perfil de Grado 1.2 (respaldo previo a revision).docx`.

---

## 1. Resumen ejecutivo

El código es una **maqueta de interfaz navegable**: 1839 líneas, 3 pantallas con contenido real y una única transición condicional. **0 de 9 alcances declarados están implementados**; 4 tienen solo fachada visual (botones/campos sin lógica) y 5 no tienen ni eso. El objetivo específico 5 ("evaluar mediante pruebas") está incumplido de forma verificable: el único test del proyecto es el boilerplate del contador de `flutter create` y prueba un archivo huérfano (`main_backup.dart`), no la aplicación real.

El defecto más grave, por encima de cualquier ausencia de alcance, es que **el resultado de "Buscar ruta" no depende del destino elegido**: cualquier selección entre los 3 destinos disponibles devuelve exactamente las mismas dos líneas, tiempos y tarifas (`resultado_ruta_screen.dart:76-96`). Es detectable por un tribunal en menos de un minuto probando dos destinos seguidos.

El documento, por su parte, tenía: bibliografía duplicada tres veces, una "referencia" que en realidad es la guía de normas APA (no una fuente citada), rangos de página idénticos y sospechosos en citas de autores distintos, secciones técnicas completas sin ninguna cita (Dart, Flutter, SQLite, MVC, UML 2, Ingeniería de Sistemas, CRM), dos secciones totalmente vacías (Dashboard y Métricas; Prueba de Software), un subtítulo duplicado ("Generalidades" x2), errores de tilde, y un párrafo que quedaba cortado en la palabra suelta "El".

**Se corrigió en el Word** todo lo anterior: typos, duplicados, bibliografía reconstruida (18 fuentes, todas con DOI o URL verificable, 16 de ellas ≤5 años), 14 citas nuevas insertadas en el cuerpo del texto, y contenido nuevo redactado para las dos secciones vacías. **No se modificó ningún archivo de código** — la revisión de código fue solo diagnóstica, tal como se le indicó a los agentes.

---

## 2. Observaciones de la docente — estado de cada punto

Fuente: `Docs/Observaciones.txt`.

| # | Observación de la docente | Estado tras esta revisión |
|---|---|---|
| 1 | "El apartado [2.1] queda con la palabra 'El' suelta y sin contenido" | **Corregido.** Se redactó un párrafo introductorio completo para 2.1 Marco Tecnológico. |
| 2 | KST Skills sin fuente que lo respalde | **Parcialmente corregido / requiere acción del estudiante.** No existe literatura académica pública sobre el modelo KST Skills del TECBA (es un modelo institucional interno). No se fabricó una cita falsa. **Pendiente:** el estudiante debe solicitar al TECBA el documento oficial del modelo SAETA/KST Skills y citarlo como fuente institucional primaria. |
| 3 | Se cita Aleman (2023) para describir SAETA pero es solo la página institucional, "NADA QUE VER" | **No corregido — requiere fuente que no está disponible públicamente.** Se mantuvo la referencia en la bibliografía (es una URL real y accesible) pero **se recomienda que el estudiante la reemplace** por el reglamento o malla curricular oficial del TECBA, no citado aquí por no ser un documento verificable desde una búsqueda pública. |
| 4 | Falta tilde en "Métodos" (2.1.2) | **Corregido.** |
| 5 | Custer et al. (2001) y Murray (2019) citados con "pp. 50-60" idénticos en ambos, "poco probable, algo turbio" | **Corregido.** Se verificaron las páginas reales contra Crossref: Custer et al. (2001) es *Journal of Technology Education* 12(2), pp. 5-20; Murray et al. (2019) es *Journal of Engineering Education* 108(2), pp. 248-275 (además, la cita original solo acreditaba a "Murray, J. K." cuando el artículo real tiene 5 autores — también corregido). El "pp. 50-60" que vio la docente no aparece en la versión actual del documento revisada aquí; puede haber correspondido a una versión anterior del archivo. |
| 6 | Borgianni et al. (2021) citado como "Borgianni y otros, 2021, págs. 50-60" | **Corregido.** El artículo es *Design Science* 7, artículo e12 (no tiene rango de páginas tipo "50-60", es un artículo con número de artículo). Cita en texto normalizada a formato APA 7 `(Borgianni et al., 2021)`. |
| 7 | Falta tilde en "Gerencia Ágil" (encabezado) | **Corregido.** |
| 8 | Cita de Dong (2024) mal formada: "Dong , What is Agile Project Management?..." | **Corregido en la bibliografía** (formato APA 7 completo: autores, año, título, revista, volumen, páginas, DOI). |
| 9 | Los 12 principios se atribuyen a "Iqbal (2022)" pero no se cita el Manifiesto Ágil original | **Corregido.** Se agregó la cita del Manifiesto Ágil original: Beck et al. (2001), *Manifesto for Agile Software Development*, con enlace a agilemanifesto.org. (No se encontró ninguna mención a "Iqbal" en el texto actual del documento — puede haber sido eliminada ya en una revisión previa). |
| 10 | Se menciona que se usará Scrum en 2.1.4 pero "no corresponde en este capítulo" | **No modificado — es una decisión de estructura del documento, no de contenido.** Se deja consignado: la docente considera que la mención a Scrum como metodología de proyecto no pertenece al capítulo de Marco Tecnológico general, sino a la sección 2.2.2 (donde también aparece, redundantemente). El estudiante/tutor debe decidir si se elimina la mención en 2.1.4 o se deja como anticipo. |
| 11 | Título "2.2.1 Técnicas de Recopilación de Información" con errores de tilde | **Corregido.** |
| 12 | Subtítulo "Generalidades" repetido dos veces con contenido distinto | **Corregido.** Se eliminó el subtítulo duplicado, manteniendo ambos bloques de contenido bajo un solo "Generalidades". |
| 13 | 2.2.1 no indica si la técnica se aplicó en el proyecto ni a qué proceso | **Corregido.** Se agregó un párrafo de cierre que vincula explícitamente entrevistas/encuesta/observación con el Objetivo Específico 1 y con los usuarios/conductores de Cochabamba. |
| 14 | Definición de Ingeniería de Sistemas sin cita | **Corregido.** Se agregó cita (Wilking et al., 2024). |
| 15 | Scrum descrito sin cita (2.2.2) | **Corregido.** Se agregaron citas (Schwaber & Sutherland, 2020) y, para metodologías ágiles en general, (Flores-Cerna et al., 2021). |
| 16 | Errores de tilde en "2.2.3 Herramientas de Programación" | **Corregido.** |
| 17 | Dart y Flutter descritos sin cita | **Corregido.** Se agregaron citas (Kinari et al., 2024; Jadaun et al., 2023) para Dart y (Kinari et al., 2024) para Flutter. |
| 18 | "2.2.4 Geestores de Base de Datos" — typo | **Corregido** → "Gestores de Base de Datos". |
| 19 | SQLite descrito sin cita | **Corregido.** Se agregó cita (Lima Torres, 2021). |
| 20 | "2.2.5 Arquitectura de Software" sin ninguna cita | **Corregido.** Se agregaron citas (Enríquez et al., 2023) tanto en la introducción de arquitectura como en el apartado de MVC. |
| 21 | "2.2.6 Lenguaje de Modelamiento UML 2" sin ninguna cita | **Corregido.** Se agregó cita (Ramírez Jiménez et al., 2024). |
| 22 | 2.2.7 CRM: "SE EXIGE QUE A PARTIR DE AHORA ELABORE UN CRM PARA SU PROYECTO DE GRADO" | **Parcialmente atendido — requiere trabajo sustantivo del estudiante, no solo una cita.** Se agregó cita de respaldo (Checasaca-Julca et al., 2022) al párrafo teórico existente sobre CRM. **Esto NO satisface la exigencia de la docente**, que pide elaborar un CRM completo para el proyecto de grado (documento de gestión de relación con el "cliente"/usuario, no solo un párrafo teórico). Queda como tarea pendiente explícita para el estudiante y su tutor. |
| 23 | "2.2.8 Dashboard y Métricas" — vacío, "¿Por qué vacío???" | **Corregido.** Se redactaron dos párrafos con definición de dashboard/KPI, cita (Calle Paz & Valles Coral, 2021), y aplicación concreta al proyecto (métricas de uso, rutas más consultadas). |
| 24 | "2.2.9 Prueba de Software" — vacío, "¿Y quién lo hará???" | **Corregido.** Se redactaron dos párrafos: definición con cita (Ramírez B. et al., 2022) y una respuesta explícita a "quién lo hará" (el propio desarrollador, durante las iteraciones de Scrum, con pruebas funcionales manuales + pruebas unitarias/widget de Flutter Test). **Nota importante:** esto es una declaración de intención en el documento; el código real hoy **no tiene ningún test que cumpla esta promesa** (ver sección 4). |
| 25 | "2.3???" — numeración rota | **No verificado en esta revisión** (no se localizó una sección "2.3" en el documento actual; puede haberse corregido ya o referirse a una versión anterior). |
| 26 | Referencias duplicadas | **Corregido.** La bibliografía aparecía completa **tres veces** en el documento (con el encabezado "BIBLIOGRAFIA" repetido dos veces), y dentro de cada bloque "Aleman, T. B. (2023)" aparecía duplicado. Se reconstruyó como un único bloque de 18 referencias, sin duplicados. |
| 27 | Aparece "EDICIÓN, A. 7. (18 de 05 de 2024). APA 7MA EDICIÓN." como si fuera una fuente citada | **Corregido.** Se eliminó esa entrada — es la guía de formato APA que el estudiante usó como referencia de estilo, no una fuente citada en el texto, y no corresponde en la bibliografía. |
| 28 | Rangos de página idénticos "pp. 50-60" en varios autores distintos | **Corregido** (ver punto 5 y 6 arriba: verificado contra Crossref, sin rangos de página fabricados). |
| 29 | "EN GENERAL EL AVANCE DEL PROYECTO ES UNA LÁGRIMA..." | Ver resumen ejecutivo y secciones 3-4: la distancia entre lo que promete el documento y lo que existe en el código sigue siendo muy grande. Las correcciones de esta revisión son de **forma y de citas**, no resuelven la falta de funcionalidad real de la aplicación. |

---

## 3. Código vs. objetivos y alcances del Perfil de Grado

*(Síntesis del arbitraje de Padre sobre los reportes de Gula, Soberbia, Ira y Pereza — ver `lib/` del proyecto, sin modificar. Verificado además por ejecución real de `flutter analyze` y `flutter test`.)*

### 3.1 Objetivos específicos

| Objetivo específico | Estado | Evidencia |
|---|---|---|
| OE1. Analizar el sistema de transporte y necesidades de usuarios | No evaluable desde el código (es trabajo documental) | Indicio indirecto: solo existen 2 líneas de transporte en todo el código, como literales — no hay rastro de un catálogo analizado. |
| OE2. Diseñar estructura funcional e interfaz de usuario | **Parcial** | Interfaz: cumplida (navegación real, tema centralizado, widgets reutilizables). Estructura funcional/modelo de datos: ausente. |
| OE3. Implementar geolocalización y visualización de rutas | **Ausente (total)** | Cero permisos en `AndroidManifest.xml`/`Info.plist`; cero paquetes de mapas o geolocalización en `pubspec.yaml`; botones "Ver mapa"/"Líneas cercanas" con callback vacío (`inicio_screen.dart:169,175`). |
| OE4. Integrar consultas de horarios/distintivos/tarifas/tiempos | **Ausente en lo funcional, fachada en lo visual** | `resultado_ruta_screen.dart:76-96`: dos tarjetas con datos fijos que no varían según ninguna entrada. |
| OE5. Evaluar mediante pruebas | **Ausente**, verificado por ejecución | `flutter test` corre 1 test: "Counter increments smoke test" (boilerplate), que monta `MyApp` de `lib/main_backup.dart`, no `TransporteApp` de `lib/main.dart`. Cobertura real de la app: 0%. |

### 3.2 Alcances declarados (9)

| # | Alcance | Estado |
|---|---|---|
| 1 | Gestión de información de líneas | Ausente |
| 2 | Consulta de rutas mediante mapas digitales | Ausente |
| 3 | Ubicación y líneas cercanas por geolocalización | Ausente (fachada) |
| 4 | Tarifas generales y preferenciales | Ausente (fachada; "preferencial" no existe en el código) |
| 5 | Horarios aproximados y tiempos estimados | Ausente (fachada; literales fijos) |
| 6 | Búsqueda por origen y destino | Ausente (fachada; el origen nunca se captura, el campo de texto libre descarta lo escrito) |
| 7 | Distintivos de línea | Ausente (solo texto plano, único asset es el logo) |
| 8 | Almacenamiento local offline (SQLite) | Ausente (sin ninguna dependencia de persistencia) |
| 9 | Gestión y actualización de líneas registradas | Ausente (actualizar una tarifa hoy requiere recompilar la app) |

**Marcador: 0 de 9 alcances implementados.**

### 3.3 Hallazgo más grave (defecto activo, no solo ausencia)

> El resultado de "Buscar ruta" **no depende del destino seleccionado**. `resultado_ruta_screen.dart:76-96` siempre muestra "Línea 134" y "Línea 01" con los mismos tiempos y tarifas, sin importar cuál de los 3 destinos se haya elegido — el parámetro `destino` solo se usa como texto decorativo (línea 48-49). Es la demostración que un tribunal puede descubrir por accidente en el flujo normal de una demo, probando dos destinos seguidos.

### 3.4 Contradicciones documento ↔ código (por gravedad)

1. **SQLite**: el documento lo describe como base de datos del sistema; no existe ninguna persistencia de ningún tipo en el código (ni siquiera permiso de INTERNET).
2. **Arquitectura por capas / MVC**: solo existe la Vista (widgets). Las carpetas `lib/models/`, `lib/data/`, `lib/services/` existen creadas mas están completamente vacías — hubo intención de armar esa arquitectura y nunca se ejecutó.
3. **UML 2**: se revisaron las 4 imágenes incrustadas en el Word — ninguna es un diagrama UML real aplicado al proyecto (son mapas conceptuales del índice temático). El mapa de la sección UML 2 tiene, además, errores propios: "Diagrama de caso de uso" aparece repetido 3 veces y dos etiquetas quedan cortadas ("Diagrama de", "Pruebas de"). No hay ningún diagrama de clases, casos de uso o actividades específico de esta aplicación en el documento.
4. **Geolocalización**: prometida en alcance 3, ausente a nivel de permisos y de paquete.
5. **Pruebas de software**: objetivo específico 5, incumplido y verificado por ejecución real de `flutter test`.
6. **Scrum**: no verificable desde el repositorio — el proyecto **no tiene git inicializado**, por lo que no hay evidencia recuperable de incrementos o sprints (pudo practicarse fuera del repo).

### 3.5 Otros hallazgos de calidad de código

- **178 líneas muertas (9,7% del proyecto):** `lib/main_backup.dart` (122 líneas) y `lib/screens/inicio_screen_backup.dart` (56 líneas), sin ninguna referencia desde el árbol vivo de la app. **Advertencia:** el único test depende de `main_backup.dart`; hay que reapuntar el test antes de borrar los backups, o el proyecto queda sin ningún test que compile.
- **Datos duplicados con esquemas incompatibles:** los mismos 3 lugares ("UMSS - Campus Central", "Plaza Colón", "Terminal de Buses") están escritos por separado en `inicio_screen.dart:192-208` (con dirección, sin funcionalidad) y en `buscar_ruta_screen.dart:199-236` (sin dirección, con funcionalidad real), sin ninguna fuente común — pese a que existe una carpeta `lib/data/` vacía, pensada exactamente para esto y nunca usada.
- **Tres convenciones de nombre de callback conviviendo:** `alSeleccionar`, `onSeleccionar`, `alPresionar` para el mismo concepto en archivos distintos.
- **El repositorio no tiene git inicializado.** Cualquier limpieza (borrar los `_backup`) sería irreversible sin antes hacer `git init` + commit.
- **Efecto colateral no solicitado:** durante la revisión, al ejecutar `flutter analyze`/`flutter test` para verificar el estado real, se actualizaron automáticamente `pubspec.lock` (4 dependencias) y `analysis_options.yaml` (excludes). Ningún archivo de código de la aplicación fue modificado. Se recomienda revisar esos dos archivos y decidir si conservarlos o revertirlos antes de hacer el primer commit.
- **Sin sobre-ingeniería:** ningún homúnculo encontró complejidad injustificada en el código existente; el problema es de ausencia de funcionalidad, no de exceso.

---

## 4. Bibliografía agregada/corregida (APA 7, todas ≤5 años salvo 2 excepciones justificadas)

Se agregaron **13 artículos académicos nuevos** (todos publicados entre 2021 y 2024, con DOI verificado contra Crossref) para respaldar cada sección del Marco Teórico que la docente señaló sin cita. Se mantienen 3 fuentes ya existentes y correctas (Borgianni et al. 2021, Custer et al. 2001, Murray et al. 2019 — corregidas en formato/páginas) y se agregó el Manifiesto Ágil original (Beck et al., 2001) por ser la fuente primaria que la propia docente exigió citar.

**Excepción a la regla de "≤5 años":** Custer et al. (2001) y Beck et al. (2001) se mantienen pese a tener más de 5 años porque son, respectivamente, un estudio clásico específico de resolución de problemas tecnológicos que ya estaba en el documento (no se encontró un reemplazo directo ≤5 años sobre exactamente ese tema) y la **fuente primaria original** del Manifiesto Ágil, que por definición no puede "actualizarse" — citar la fuente original de un manifiesto histórico es convención académica estándar independientemente de su antigüedad. Se deja esta excepción explícita para que el estudiante la valide con su tutor.

| Referencia (APA 7) | Tema que respalda | Enlace de descarga |
|---|---|---|
| Beck, K. et al. (2001). *Manifesto for Agile Software Development*. | Manifiesto Ágil original (exigido por la docente) | https://agilemanifesto.org/ |
| Borgianni, Y., Fiorineschi, L., Frillici, F., & Rotini, F. (2021). The process for individuating TRIZ inventive principles... *Design Science*, 7, e12. | TRIZ / principio de inventiva | https://doi.org/10.1017/dsj.2021.12 |
| Calle Paz, I. I., & Valles Coral, M. A. (2021). Dashboard digital para el monitoreo de indicadores... *Revista Científica de Sistemas e Informática*, 1(1). | Dashboard y métricas | https://doi.org/10.51252/rcsi.v1i1.94 |
| Checasaca-Julca, J. R. et al. (2022). Importancia de la herramienta CRM en las empresas de Latinoamérica... *Revista Científica de la UCSA*, 9(3), 97-119. | CRM | https://doi.org/10.18004/ucsa/2409-8752/2022.009.03.097 |
| Custer, R. L., Valesey, B. G., & Burke, B. N. (2001). An assessment model for a design approach to technological problem solving. *Journal of Technology Education*, 12(2), 5-20. | Métodos de resolución de problemas tecnológicos | https://doi.org/10.21061/jte.v12i2.a.1 |
| Dong, H., Dacre, N., Baxter, D., & Ceylan, S. (2024). What is agile project management?... *Project Management Journal*, 55(6), 668-688. | Gerencia ágil | https://doi.org/10.1177/87569728241254095 |
| Enríquez, F. et al. (2023). Impacto del patrón MVC en la seguridad, interoperabilidad y usabilidad... *EASI*, 2(1), 11-16. | Arquitectura de software / MVC | https://doi.org/10.53591/easi.v2i1.2043 |
| Flores-Cerna, F. et al. (2021). Metodologías ágiles: un análisis de los desafíos organizacionales... *Revista Científica*, 43(1), 38-49. | Metodologías ágiles | https://doi.org/10.14483/23448350.18332 |
| Jadaun, S., Singh, R. K., Kumar, R., & Agarwal, K. K. (2023). Analysis of cross platform application development... *IJRTE*, 12(1), 33-38. | Dart / Flutter | https://doi.org/10.35940/ijrte.A7580.0512123 |
| Kinari, S. A. et al. (2024). An independent learning system for Flutter cross-platform mobile programming... *Information*, 15(10), art. 614. | Flutter / Dart | https://doi.org/10.3390/info15100614 (acceso abierto, PDF directo en MDPI) |
| Lima Torres, S. (2021). Componente de revisión de estándar de arquitectura de datos... SQLite. *Innovación y Software*, 2(1), 20-32. | SQLite | https://revistas.ulasalle.edu.pe/innosoft/article/view/32 (PDF abierto) |
| Martínez-Rebollar, A. et al. (2022). Planificador de viajes de transporte público utilizando el estándar GTFS. *Boletín Científico INVESTIGIUM*, 8(Especial), 102-110. | Antecedentes — estándar de datos de transporte | https://doi.org/10.29057/est.v8iespecial.9994 |
| Murray, J. K. et al. (2019). Design by taking perspectives... *Journal of Engineering Education*, 108(2), 248-275. | Métodos de resolución de problemas | https://doi.org/10.1002/jee.20263 |
| Ramírez B., R. I. et al. (2022). Prácticas orientadas por pruebas para el desarrollo de software... *Revista de Iniciación Científica*, 8(2), 50-56. | Prueba de software | https://doi.org/10.33412/rev-ric.v8.2.3672 |
| Ramírez Jiménez, M. del R. et al. (2024). UML: una manera de representar, interpretar, analizar y desarrollar el pensamiento computacional. *RIDE*, 15(29), e784. | UML 2 | https://doi.org/10.23913/ride.v15i29.2196 (acceso abierto) |
| Schwaber, K., & Sutherland, J. (2020). *La Guía de Scrum*. Scrum.org. | Scrum | https://www.scrum.org/resources/scrum-guide |
| Wilking, F., Horber, D., Goetz, S., & Wartzack, S. (2024). Utilization of system models in model-based systems engineering... *Design Science*, 10, e6. | Ingeniería de Sistemas | https://doi.org/10.1017/dsj.2024.3 |

**Nota sobre acceso:** todos los DOI resuelven a la página del editor; los marcados "acceso abierto" tienen PDF descargable directo y sin barrera de pago. Los que no lo indican pueden requerir acceso institucional o compra — recomiendo verificar acceso vía la biblioteca del TECBA o Google Scholar antes de la entrega final.

**No se encontró** un artículo académico específico ≤5 años sobre el modelo institucional "KST Skills / SAETA-FH" del TECBA — es, según la evidencia disponible, un modelo pedagógico interno de la institución sin publicación académica externa indexada. Debe respaldarse con documentación oficial del TECBA, no con literatura de terceros.

---

## 5. Cambios realizados directamente en el Word

Archivo editado: `Docs/Perfil de Grado 1.2.docx` (se conserva copia de seguridad del original: `Docs/Perfil de Grado 1.2 (respaldo previo a revision).docx`).

1. Corregidos 7 encabezados con errores de tilde/typo (Marco Tecnológico, Métodos, Gerencia Ágil, Técnicas de Recopilación de Información, Herramientas de Programación, Gestores de Base de Datos, Dashboard y Métricas).
2. Completado el párrafo huérfano "El" al inicio de 2.1 con una introducción real del capítulo.
3. Eliminado el subtítulo "Generalidades" duplicado.
4. Eliminado un párrafo huérfano que solo contenía un punto (".").
5. Agregadas 14 citas en texto (formato APA 7) en las secciones que no tenían ninguna: métodos de resolución de problemas, TRIZ, Manifiesto Ágil, Scrum (x2), Ingeniería de Sistemas, metodologías ágiles, Dart, Flutter, SQLite, arquitectura de software, MVC, UML 2, CRM.
6. Agregado un párrafo de cierre en 2.2.1 vinculando las técnicas de recopilación con el Objetivo Específico 1.
7. Redactado contenido nuevo completo (antes vacío) para 2.2.8 Dashboard y Métricas y 2.2.9 Prueba de Software, cada uno con su cita de respaldo.
8. Eliminados 6 párrafos "List Paragraph" vacíos residuales (viñetas fantasma sin contenido).
9. Reconstruida la bibliografía completa: de 3 bloques duplicados (con una entrada falsa y citas mal formadas) a un único bloque de **18 referencias**, alfabetizadas, formato APA 7, con itálicas en los nombres de revista.

**No se tocó** el árbol de capítulos I, III en adelante, ni los anexos, ni se modificó ningún archivo dentro de `lib/`, `android/`, `ios/` ni `pubspec.yaml`.

---

## 6. Pendientes que requieren decisión del estudiante y/o del tutor (no resueltos aquí)

1. **¿El documento todavía admite correcciones formales, o ya fue evaluado/cerrado?** Determina si conviene reescribir el Marco Teórico para describir honestamente lo que el código es hoy ("prototipo de interfaz con datos estáticos") o si hay que implementar funcionalidad real para sostener lo ya escrito.
2. **CRM exigido por la docente:** la cita agregada es solo el respaldo teórico del párrafo existente; **no** constituye el CRM completo que la docente exige elaborar para el proyecto de grado. Es una tarea pendiente sustantiva.
3. **Fuente institucional de KST Skills/SAETA:** reemplazar Aleman (2023) por el documento oficial del TECBA.
4. **Prioridad de arreglo de código**, si se decide implementar (sugerida por la síntesis, no ejecutada): (a) reapuntar el test a la app real y borrar los `_backup` (requiere `git init` primero); (b) crear `lib/models`+`lib/data` con listas estáticas únicas para eliminar la duplicación y arreglar el defecto de que el resultado no depende del destino; (c) recién después, evaluar SQLite real y geolocalización/mapas mínimos.
5. **Revisar si conservar o revertir** los cambios automáticos que `flutter analyze`/`flutter test` hicieron en `pubspec.lock` y `analysis_options.yaml` durante esta revisión.
6. **Sección "2.3???"** mencionada por la docente no se localizó en la versión actual — confirmar si ya fue corregida o si sigue pendiente en otra parte del documento.
