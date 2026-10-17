# Contexto para herramientas de IA

Implementación en SwiftUI de la app de fichas de estudio, para iPhone, iPad y Mac. Es una de las dos implementaciones del reto de desarrollo cruzado entre Jorge Johnson y Sergio Monsalve.

El contexto del proyecto, las reglas de la especificación y la regla de privacidad están en `especificacion/AGENTS.md`. Léelo primero; todo lo que dice aplica aquí.

## Reglas de esta implementación

- La especificación manda. No implementar comportamiento que no esté en `especificacion/specs/` o en `especificacion/pruebas/`. Si falta algo, proponerlo como issue en el repo de especificación.
- No modificar archivos dentro de `especificacion/`; es un submódulo de otro repo.
- TDD: primero una prueba que falla, después el código mínimo, después refactorizar. Las pruebas de dominio recorren `especificacion/pruebas/casos/*.json`; no copiar los casos al código.
- La lógica va en `Sources/FichasCore/`, sin importar SwiftUI ni frameworks de Apple que no existan en Linux, para que corra en el CI. La interfaz va en `App/`.
- Swift 5.10 o posterior, iOS 17 y macOS 14 como mínimo. Para persistencia, SwiftData.
- Antes de proponer un cambio: `swift test`, y si tocaste `App/`, compilar en Xcode para iOS y macOS.
- El proyecto de Xcode se genera con `xcodegen` desde `project.yml`; no se versiona el `.xcodeproj`.
- Commits y textos en español.
