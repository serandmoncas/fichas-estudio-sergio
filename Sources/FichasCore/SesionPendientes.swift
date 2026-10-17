// Selección de fichas para la sesión de pendientes del día.
// Especificación: especificacion/pruebas/casos/sesion-pendientes.json (issues #1 y #3, estado propuesta).

/// Lo mínimo de una ficha que hace falta para decidir si entra a la sesión.
public struct FichaProgramada: Equatable, Sendable {
    public let id: String
    /// Fecha local del próximo repaso en formato AAAA-MM-DD, o `nil` si la ficha es nueva.
    public let proximoRepaso: String?

    public init(id: String, proximoRepaso: String?) {
        self.id = id
        self.proximoRepaso = proximoRepaso
    }
}

/// Resultado de armar la sesión.
public struct SeleccionSesion: Equatable, Sendable {
    /// Ids de las fichas vencidas (próximo repaso hoy o antes). El orden no forma parte del contrato.
    public let repasos: [String]
    /// Cuántas fichas nuevas entran, como máximo `limiteNuevas`.
    public let cantidadNuevas: Int

    public init(repasos: [String], cantidadNuevas: Int) {
        self.repasos = repasos
        self.cantidadNuevas = cantidadNuevas
    }
}

/// Arma la sesión de pendientes del día.
///
/// - Parameters:
///   - hoy: fecha local de hoy, AAAA-MM-DD.
///   - fichas: las fichas candidatas.
///   - limiteNuevas: máximo de fichas nuevas por sesión.
public func seleccionarPendientes(
    hoy: String,
    fichas: [FichaProgramada],
    limiteNuevas: Int
) -> SeleccionSesion {
    // AAAA-MM-DD ordena igual como texto que como fecha.
    let repasos = fichas.filter { ficha in
        guard let proximo = ficha.proximoRepaso else { return false }
        return proximo <= hoy
    }.map(\.id)
    let nuevas = fichas.filter { $0.proximoRepaso == nil }.count
    return SeleccionSesion(repasos: repasos, cantidadNuevas: min(nuevas, limiteNuevas))
}
