// Sesión y Respuesta (especificacion/specs/02-modelo-de-datos.md, REQ-020 a REQ-022, REQ-026, REQ-030).
#if canImport(SwiftData)
import FichasCore
import Foundation
import SwiftData

@Model
public final class Sesion {
    public var inicio: Date
    /// `nil` mientras la sesión está en curso.
    public private(set) var fin: Date?
    /// Lo que agrupa la sesión (REQ-021).
    public var categorias: [Categoria]
    public var subcategorias: [Subcategoria]
    /// Cuántas fichas pidió el estudiante al iniciar (REQ-022).
    public var fichasSolicitadas: Int
    /// Al borrar la sesión se borra su registro.
    @Relationship(deleteRule: .cascade, inverse: \Respuesta.sesion)
    public var respuestas: [Respuesta] = []

    public var enCurso: Bool { fin == nil }

    public init(inicio: Date, categorias: [Categoria] = [], subcategorias: [Subcategoria] = [], fichasSolicitadas: Int) {
        self.inicio = inicio
        self.categorias = categorias
        self.subcategorias = subcategorias
        self.fichasSolicitadas = fichasSolicitadas
    }

    public func terminar(en fecha: Date) {
        fin = fecha
    }
}

/// Una fila por cada ficha mostrada en una sesión (REQ-030).
@Model
public final class Respuesta {
    public var sesion: Sesion?
    /// `nil` si la ficha se borró después; la respuesta se conserva en el registro de la sesión.
    public var ficha: Ficha?
    public var mostradaEn: Date
    /// SwiftData no sabe guardar un enum con valores asociados, así que se guarda como texto.
    private var calificacionTexto: String
    public var tiempoRespuestaSegundos: Double
    /// Solo aplica a fichas con tiempo (REQ-017).
    public var tiempoAgotado: Bool

    public init(
        ficha: Ficha,
        mostradaEn: Date,
        calificacion: CalificacionOriginal,
        tiempoRespuestaSegundos: Double,
        tiempoAgotado: Bool
    ) {
        self.ficha = ficha
        self.mostradaEn = mostradaEn
        self.calificacionTexto = calificacion.texto
        self.tiempoRespuestaSegundos = tiempoRespuestaSegundos
        self.tiempoAgotado = tiempoAgotado
    }

    /// La autocalificación tal como la dio el estudiante (REQ-026).
    public var calificacion: CalificacionOriginal {
        get { CalificacionOriginal(texto: calificacionTexto) }
        set { calificacionTexto = newValue.texto }
    }
}

private extension CalificacionOriginal {
    /// "1" a "5", "pasa" o "no_pasa", como en los casos compartidos.
    var texto: String {
        switch self {
        case .escala(let n): String(n)
        case .pasa: "pasa"
        case .noPasa: "no_pasa"
        }
    }

    init(texto: String) {
        switch texto {
        case "pasa": self = .pasa
        case "no_pasa": self = .noPasa
        default:
            // Solo se guarda lo que produce `texto`, así que aquí siempre llega un número.
            self = .escala(Int(texto) ?? 0)
        }
    }
}
#endif
