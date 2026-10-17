// Ficha (especificacion/specs/02-modelo-de-datos.md, REQ-010 a REQ-017).
#if canImport(SwiftData)
import FichasCore
import SwiftData

/// Campo de texto adicional de una ficha (REQ-015).
public struct CampoAdicional: Codable, Equatable, Sendable {
    public var nombre: String
    public var texto: String

    public init(nombre: String, texto: String) {
        self.nombre = nombre
        self.texto = texto
    }
}

@Model
public final class Ficha {
    public var pregunta: String
    public var respuesta: String
    /// Siempre tiene valor (REQ-014). SwiftData exige que las relaciones sean opcionales.
    /// Se cambia con `mover(a:)`, que mantiene la subcategoría coherente.
    public private(set) var categoria: Categoria?
    /// Opcional; si tiene valor, es de la misma categoría (REQ-014).
    public private(set) var subcategoria: Subcategoria?
    public var camposAdicionales: [CampoAdicional]
    public var tipoCalificacion: TipoCalificacion
    /// `nil` si la ficha no tiene límite de tiempo (REQ-017). Reemplaza al par
    /// `con_tiempo` / `tiempo_maximo_segundos` del modelo de datos, para que no
    /// pueda existir una ficha con tiempo y sin tiempo máximo.
    public var tiempoMaximoSegundos: Int?
    /// Al borrar la ficha, sus respuestas quedan en el registro de la sesión (REQ-030).
    @Relationship(deleteRule: .nullify, inverse: \Respuesta.ficha)
    public var respuestas: [Respuesta] = []

    public var conTiempo: Bool { tiempoMaximoSegundos != nil }

    public init(
        pregunta: String,
        respuesta: String,
        categoria: Categoria,
        subcategoria: Subcategoria? = nil,
        camposAdicionales: [CampoAdicional] = [],
        tipoCalificacion: TipoCalificacion,
        tiempoMaximoSegundos: Int? = nil
    ) throws {
        self.pregunta = pregunta
        self.respuesta = respuesta
        self.categoria = categoria
        self.camposAdicionales = camposAdicionales
        self.tipoCalificacion = tipoCalificacion
        self.tiempoMaximoSegundos = tiempoMaximoSegundos
        try asignar(subcategoria: subcategoria)
    }

    /// Cambia la subcategoría. Falla si no es de la categoría de la ficha (REQ-014).
    public func asignar(subcategoria: Subcategoria?) throws {
        if let subcategoria, subcategoria.categoria !== categoria {
            throw ErrorDatos.subcategoriaDeOtraCategoria
        }
        self.subcategoria = subcategoria
    }

    /// Pasa la ficha a otra categoría. La subcategoría era de la categoría anterior, así que se quita.
    public func mover(a categoria: Categoria) {
        guard categoria !== self.categoria else { return }
        self.categoria = categoria
        subcategoria = nil
    }
}
#endif
