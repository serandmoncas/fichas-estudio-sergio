// Programación del próximo repaso (REQ-024, REQ-025).
// El algoritmo es FSRS si se acepta el issue #1 de la especificación; esta interfaz
// deja a FichasCore sin depender de una librería concreta.

/// En qué etapa del aprendizaje está una ficha.
public enum FaseRepaso: String, Codable, Equatable, Sendable {
    case nueva
    case aprendiendo
    case repaso
    case reaprendiendo
}

/// Lo que hay que guardar de una ficha para programar su próximo repaso.
/// Las fechas son locales, en formato AAAA-MM-DD, como en los casos SES.
public struct EstadoRepaso: Codable, Equatable, Sendable {
    public var estabilidad: Double
    public var dificultad: Double
    public var diasProgramados: Int
    public var repasos: Int
    public var olvidos: Int
    public var fase: FaseRepaso
    public var ultimoRepaso: String
    public var proximoRepaso: String

    public init(estabilidad: Double, dificultad: Double, diasProgramados: Int, repasos: Int, olvidos: Int,
                fase: FaseRepaso, ultimoRepaso: String, proximoRepaso: String) {
        self.estabilidad = estabilidad
        self.dificultad = dificultad
        self.diasProgramados = diasProgramados
        self.repasos = repasos
        self.olvidos = olvidos
        self.fase = fase
        self.ultimoRepaso = ultimoRepaso
        self.proximoRepaso = proximoRepaso
    }
}

public enum ErrorProgramador: Error, Equatable {
    /// La fecha no tiene el formato AAAA-MM-DD.
    case fechaInvalida(String)
}

public protocol Programador {
    /// Calcula el nuevo estado de una ficha después de calificarla.
    ///
    /// - Parameters:
    ///   - estado: el estado actual, o `nil` si la ficha es nueva.
    ///   - calificacion: la calificación ya traducida (ver `traducirCalificacion`).
    ///   - hoy: fecha local del repaso, AAAA-MM-DD.
    func programar(_ estado: EstadoRepaso?, calificacion: CalificacionFSRS, hoy: String) throws -> EstadoRepaso
}
