import FichasCore
import FichasDatos
import SwiftData
import SwiftUI

/// Resultado de una sesión (REQ-030), al terminarla o desde el historial.
/// Qué se muestra es la pregunta abierta 16.
struct ResumenView: View {
    let sesion: Sesion
    /// `true` justo al terminar la sesión; `false` cuando se abre desde el historial.
    var recienTerminada = false

    private var respuestas: [Respuesta] { sesion.respuestas.sorted { $0.mostradaEn < $1.mostradaEn } }

    private var resumen: ResumenSesion<PersistentIdentifier> {
        resumirSesion(respuestas.map {
            RespuestaResumible(id: $0.persistentModelID, calificacion: $0.calificacion,
                               tiempoAgotado: $0.tiempoAgotado, tiempoRespuestaSegundos: $0.tiempoRespuestaSegundos)
        })
    }

    var body: some View {
        let resumen = resumen
        let porId = Dictionary(uniqueKeysWithValues: respuestas.map { ($0.persistentModelID, $0) })
        List {
            Section {
                VStack(spacing: 8) {
                    if recienTerminada {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 48)).foregroundStyle(.green)
                        Text("Terminaste por hoy").font(.title2.bold())
                    } else {
                        Text(sesion.inicio.formatted(date: .complete, time: .shortened)).font(.headline)
                        if sesion.enCurso {
                            Label("Sin terminar", systemImage: "pause.circle").foregroundStyle(.orange)
                        }
                    }
                    Text("\(resumen.total) de \(sesion.fichasSolicitadas) fichas").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Cómo te fue") {
                ForEach([CalificacionFSRS.facil, .bien, .dificil, .otraVez], id: \.self) { calificacion in
                    LabeledContent(calificacion.nombre, value: "\(resumen.porCalificacion[calificacion, default: 0])")
                }
            }

            Section("Tiempo") {
                if let fin = sesion.fin {
                    LabeledContent("Duración", value: Duration.seconds(fin.timeIntervalSince(sesion.inicio))
                        .formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated)))
                }
                if let promedio = resumen.tiempoPromedioSegundos {
                    LabeledContent("Promedio por ficha", value: "\(promedio.formatted(.number.precision(.fractionLength(0...1)))) s")
                }
            }

            if !resumen.paraRepasar.isEmpty {
                Section("Para repasar") {
                    ForEach(resumen.paraRepasar, id: \.self) { id in
                        // La ficha puede haberse borrado después; la respuesta se conserva (REQ-030).
                        Text(porId[id]?.ficha?.pregunta ?? "Ficha eliminada")
                    }
                }
            }
        }
    }
}

extension CalificacionFSRS {
    var nombre: String {
        switch self {
        case .otraVez: "Otra vez"
        case .dificil: "Difícil"
        case .bien: "Bien"
        case .facil: "Fácil"
        }
    }
}
