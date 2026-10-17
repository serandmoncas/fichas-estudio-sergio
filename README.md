# Fichas: implementación de Sergio

Implementación en SwiftUI de la [aplicación de fichas de estudio](https://github.com/Exp-IA/fichas-estudio-specs), para iPhone, iPad y Mac.

- **Especificación:** [Exp-IA/fichas-estudio-specs](https://github.com/Exp-IA/fichas-estudio-specs), enlazada como submódulo en `especificacion/`.
- **Versión de la especificación:** sin publicar, después de la 0.1 (ver `especificacion/CHANGELOG.md`).

## Estructura

| Ruta | Contenido |
|---|---|
| `Sources/FichasCore/` | Lógica de dominio: calificación, sesiones, selección, resumen. Sin SwiftUI ni frameworks solo de Apple |
| `Sources/FichasDatos/` | Persistencia con SwiftData (en Linux compila vacío) y datos de ejemplo |
| `Tests/FichasCoreTests/` | Pruebas que recorren los casos compartidos de `especificacion/pruebas/casos/` |
| `Tests/FichasDatosTests/` | Pruebas de los modelos y sus reglas (eliminar, subcategorías) |
| `App/` | Interfaz SwiftUI multiplataforma |
| `UITests/` | Pruebas de interfaz del flujo completo en el simulador de iOS |
| `project.yml` | Definición del proyecto de Xcode (XcodeGen) |
| `especificacion/` | Submódulo con la especificación y los casos de prueba |

La lógica vive en un paquete Swift aparte para que las pruebas corran rápido, sin simulador, en el Mac y en el CI.

## Primeros pasos en el Mac

```bash
git clone --recurse-submodules https://github.com/Exp-IA/fichas-estudio-sergio.git
cd fichas-estudio-sergio

# Pruebas del dominio
swift test

# Proyecto de Xcode
brew install xcodegen
xcodegen
open Fichas.xcodeproj
```

En Xcode, elige el destino (iPhone, iPad o "My Mac") y corre con ⌘R. Para instalarla en tu iPhone y iPad, selecciona tu equipo de desarrollo en Signing & Capabilities.

Si ya clonaste sin `--recurse-submodules`: `git submodule update --init`.

## TDD

Cada función de `FichasCore` empieza lanzando `noImplementado`, así que sus pruebas fallan a propósito hasta que se implementa. El ciclo es:

1. Elegir un caso que falla (por ejemplo `CAL-001`).
2. Escribir el código mínimo para que pase.
3. Refactorizar con todas las pruebas en verde.

Los casos vienen del repo de especificación. Si uno parece incorrecto, se abre un issue allá con la plantilla "Error en la especificación"; no se cambia aquí.

Para traer casos nuevos de la especificación:

```bash
git submodule update --remote especificacion
```

## Estado

| Área | Casos | Estado |
|---|---|---|
| Traducción de calificaciones | CAL-001 a CAL-009 | Implementado (casos en propuesta, issue #2) |
| Sesión de pendientes | SES-001 a SES-006 | Implementado (casos en propuesta, issue #3) |
| Selección de sesión manual | Casos SEL propuestos en la especificación (#22) | Implementado |
| Resumen de sesión | Pregunta abierta 16 | Implementado (lo mínimo) |
| Algoritmo FSRS | REP-001 y REP-002, propuestos (#21) | En el PR #6, en borrador hasta que se decida el issue #1 |
| Persistencia (SwiftData) | | Implementado. Eliminar una categoría con fichas se bloquea (pregunta abierta 17) |
| Pantallas mínimas | `04-interfaz.md` | Las seis, con pruebas de interfaz |
| Importar mazos | Formato propuesto en el issue #6 | Prototipo, solo en DEBUG |
| Sincronización (iCloud) | | Para después |

## Datos de ejemplo

Para probar a mano, abre la app con el argumento `-datos-ejemplo` (solo en DEBUG). Carga 3 categorías, 16 fichas y 2 sesiones, si todavía no hay categorías.

- Xcode: Product → Scheme → Edit Scheme → Run → Arguments.
- Terminal: `xcrun devicectl device process launch --device <id> co.expia.Fichas -- -datos-ejemplo`.

## Importar un mazo

Prototipo del formato propuesto en el issue #6 de la especificación; puede cambiar. Solo en DEBUG.

1. Copia el archivo a la carpeta de la app: `xcrun devicectl device copy to --device <id> --domain-type appDataContainer --domain-identifier co.expia.Fichas --source mazo.json --destination Documents/mazo.json`.
2. Abre la app con el argumento: `xcrun devicectl device process launch --device <id> co.expia.Fichas -- -importar-mazo Documents/mazo.json`.

Las categorías y subcategorías con el mismo nombre se reutilizan, y una ficha con la misma pregunta en la misma categoría no se repite, así que importar dos veces no duplica nada. Si el archivo tiene un error, no se importa nada. La cita de cada ficha queda como campo adicional "Fuente", con su "Enlace".

## CI

En cada push y pull request, GitHub Actions corre:

- **Dominio:** compila FichasCore y corre las pruebas compartidas en Linux.
- **App:** genera el proyecto y compila la app para macOS y para el simulador de iOS.
