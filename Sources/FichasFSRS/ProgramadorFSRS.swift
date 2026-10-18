// Programador con swift-fsrs (fork con el arreglo de open-spaced-repetition/swift-fsrs#38).
import FichasCore
import Foundation
import FSRS

/// FSRS-6 con la configuración propuesta en el issue #1 de la especificación:
/// pesos por defecto, sin fuzz y solo días enteros (sin pasos de corto plazo).
public struct ProgramadorFSRS: Programador {
    private let fsrs: FSRS

    public init(retencion: Double = 0.9) {
        fsrs = FSRS(parameters: .init(
            requestRetention: retencion, w: FSRSDefaults.defaultWv6, enableFuzz: false, enableShortTerm: false
        ))
    }

    public func programar(_ estado: EstadoRepaso?, calificacion: CalificacionFSRS, hoy: String) throws -> EstadoRepaso {
        let ahora = try Self.fecha(hoy)
        let tarjeta = try estado.map(Self.tarjeta) ?? Card(due: ahora)
        let siguiente = try fsrs.next(card: tarjeta, now: ahora, grade: Self.rating(calificacion)).card
        return EstadoRepaso(
            estabilidad: siguiente.stability,
            dificultad: siguiente.difficulty,
            diasProgramados: Int(siguiente.scheduledDays),
            repasos: siguiente.reps,
            olvidos: siguiente.lapses,
            fase: Self.fase(siguiente.state),
            ultimoRepaso: hoy,
            proximoRepaso: Self.texto(siguiente.due)
        )
    }

    // MARK: - Conversiones

    // Las librerías de FSRS trabajan con instantes y cuentan los días en UTC. Cada fecha local
    // AAAA-MM-DD se representa como la medianoche UTC de ese mismo día, así los días enteros
    // de FSRS coinciden con los días locales y no hace falta saber la zona horaria.
    private static let utc: Calendar = {
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = TimeZone(identifier: "UTC")!
        return calendario
    }()

    static func fecha(_ texto: String) throws -> Date {
        let partes = texto.split(separator: "-")
        guard texto.count == 10, partes.count == 3,
              let anio = Int(partes[0]), let mes = Int(partes[1]), let dia = Int(partes[2]),
              let fecha = utc.date(from: DateComponents(year: anio, month: mes, day: dia)),
              Self.texto(fecha) == texto // rechaza "2026-1-7" o "2026-02-30"
        else { throw ErrorProgramador.fechaInvalida(texto) }
        return fecha
    }

    static func texto(_ fecha: Date) -> String {
        let c = utc.dateComponents([.year, .month, .day], from: fecha)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    private static func tarjeta(_ estado: EstadoRepaso) throws -> Card {
        Card(
            due: try fecha(estado.proximoRepaso),
            stability: estado.estabilidad,
            difficulty: estado.dificultad,
            scheduledDays: Double(estado.diasProgramados),
            reps: estado.repasos,
            lapses: estado.olvidos,
            state: cardState(estado.fase),
            lastReview: try fecha(estado.ultimoRepaso)
        )
    }

    private static func rating(_ calificacion: CalificacionFSRS) -> Rating {
        switch calificacion {
        case .otraVez: .again
        case .dificil: .hard
        case .bien: .good
        case .facil: .easy
        }
    }

    private static func fase(_ estado: CardState) -> FaseRepaso {
        switch estado {
        case .new: .nueva
        case .learning: .aprendiendo
        case .review: .repaso
        case .relearning: .reaprendiendo
        }
    }

    private static func cardState(_ fase: FaseRepaso) -> CardState {
        switch fase {
        case .nueva: .new
        case .aprendiendo: .learning
        case .repaso: .review
        case .reaprendiendo: .relearning
        }
    }
}
