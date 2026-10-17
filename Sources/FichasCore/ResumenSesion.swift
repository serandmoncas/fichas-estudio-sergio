// Resumen al terminar una sesión (REQ-030).
// Qué datos se muestran es la pregunta abierta 16; esto es lo mínimo.

/// Lo que hace falta de una respuesta para resumir la sesión.
public struct RespuestaResumible<ID: Hashable>: Equatable {
    public let id: ID
    public let calificacion: CalificacionOriginal
    public let tiempoAgotado: Bool
    public let tiempoRespuestaSegundos: Double

    public init(id: ID, calificacion: CalificacionOriginal, tiempoAgotado: Bool, tiempoRespuestaSegundos: Double) {
        self.id = id
        self.calificacion = calificacion
        self.tiempoAgotado = tiempoAgotado
        self.tiempoRespuestaSegundos = tiempoRespuestaSegundos
    }
}

public struct ResumenSesion<ID: Hashable>: Equatable {
    public let total: Int
    /// Cuántas respuestas hubo de cada calificación, en la escala común de FSRS.
    public let porCalificacion: [CalificacionFSRS: Int]
    /// Las respuestas que quedaron en Otra vez, en el orden en que se dieron.
    public let paraRepasar: [ID]
    /// `nil` si no hubo respuestas.
    public let tiempoPromedioSegundos: Double?
}

public func resumirSesion<ID: Hashable>(_ respuestas: [RespuestaResumible<ID>]) -> ResumenSesion<ID> {
    // El tipo de calificación se deduce de la calificación misma: un número es escala 1 a 5.
    let traducidas = respuestas.compactMap { r -> (ID, CalificacionFSRS)? in
        let tipo: TipoCalificacion = if case .escala = r.calificacion { .escala1a5 } else { .pasaNoPasa }
        // Una calificación inválida no se cuenta; la app no debería guardarla.
        guard let fsrs = try? traducirCalificacion(tipo: tipo, calificacion: r.calificacion, tiempoAgotado: r.tiempoAgotado)
        else { return nil }
        return (r.id, fsrs)
    }
    return ResumenSesion(
        total: respuestas.count,
        porCalificacion: Dictionary(traducidas.map { ($0.1, 1) }, uniquingKeysWith: +),
        paraRepasar: traducidas.filter { $0.1 == .otraVez }.map(\.0),
        tiempoPromedioSegundos: respuestas.isEmpty
            ? nil
            : respuestas.map(\.tiempoRespuestaSegundos).reduce(0, +) / Double(respuestas.count)
    )
}
