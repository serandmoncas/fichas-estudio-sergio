# Fichas: implementación de Sergio

Implementación en SwiftUI de la [aplicación de fichas de estudio](https://github.com/Exp-IA/fichas-estudio-specs), para iPhone, iPad y Mac.

- **Especificación:** [Exp-IA/fichas-estudio-specs](https://github.com/Exp-IA/fichas-estudio-specs), enlazada como submódulo en `especificacion/`.
- **Versión de la especificación:** sin publicar, después de la 0.1 (ver `especificacion/CHANGELOG.md`).

## Estructura

| Ruta | Contenido |
|---|---|
| `Sources/FichasCore/` | Lógica de dominio: calificación, sesiones, repetición. Sin SwiftUI |
| `Tests/FichasCoreTests/` | Pruebas que recorren los casos compartidos de `especificacion/pruebas/casos/` |
| `App/` | Interfaz SwiftUI multiplataforma |
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
| Algoritmo FSRS | Pendiente de la decisión del issue #1 | Sin empezar |
| Persistencia (SwiftData) | | Sin empezar |
| Sincronización (iCloud) | | Para después |

## CI

En cada push y pull request, GitHub Actions corre:

- **Dominio:** compila FichasCore y corre las pruebas compartidas en Linux.
- **App:** genera el proyecto y compila la app para macOS y para el simulador de iOS.
