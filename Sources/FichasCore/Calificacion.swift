// Traducción de la autocalificación a las calificaciones de FSRS.
// Especificación: especificacion/pruebas/casos/calificacion.json (issue #2, estado propuesta).

/// Las cuatro calificaciones que usa FSRS.
public enum CalificacionFSRS: String, Codable, Equatable, Sendable {
    case otraVez = "otra_vez"
    case dificil
    case bien
    case facil
}

/// Escala con la que se califica una ficha (REQ-016).
public enum TipoCalificacion: String, Codable, Equatable, Sendable {
    case escala1a5 = "escala_1_5"
    case pasaNoPasa = "pasa_no_pasa"
}

/// La calificación tal como la da el estudiante: un número de 1 a 5, o pasa / no pasa.
public enum CalificacionOriginal: Equatable, Sendable {
    case escala(Int)
    case pasa
    case noPasa
}

public enum ErrorCalificacion: Error, Equatable {
    /// La calificación no corresponde al tipo de calificación de la ficha, o está fuera de rango.
    case calificacionInvalida
    /// Marca de TDD: la función todavía no está implementada.
    case noImplementado
}

/// Traduce la autocalificación del estudiante a una calificación de FSRS.
///
/// - Parameters:
///   - tipo: el tipo de calificación de la ficha.
///   - calificacion: lo que eligió el estudiante.
///   - tiempoAgotado: si la ficha tenía tiempo máximo y se agotó (REQ-017).
/// - Throws: `ErrorCalificacion.calificacionInvalida` si la calificación no es válida para el tipo.
public func traducirCalificacion(
    tipo: TipoCalificacion,
    calificacion: CalificacionOriginal,
    tiempoAgotado: Bool
) throws -> CalificacionFSRS {
    switch calificacion {
    case .escala(1): return .otraVez
    case .escala(2): return .dificil
    case .escala(3), .escala(4): return .bien
    case .escala(5): return .facil
    default: break
    }
    // TDD: el resto de casos de calificacion.json fallan hasta que se implementen.
    throw ErrorCalificacion.noImplementado
}
