import FichasCore
import FichasDatos
import SwiftUI

/// Mostrar la pregunta, el tiempo, la respuesta y pedir la autocalificación (REQ-017, REQ-023, REQ-026).
struct EstudioView: View {
    let enCurso: SesionEnCurso

    @State private var indice = 0
    @State private var mostradaEn = Date.now
    @State private var revelada = false
    @State private var tiempoAgotado = false
    /// Desde que se mostró la pregunta hasta que se reveló la respuesta.
    @State private var tiempoRespuesta: TimeInterval = 0

    private var ficha: Ficha? { enCurso.fichas.indices.contains(indice) ? enCurso.fichas[indice] : nil }

    var body: some View {
        Group {
            if let ficha {
                tarjeta(ficha)
                    .id(indice)
                    .task(id: indice) { await esperarLimite(de: ficha) }
            } else {
                terminada
            }
        }
        .padding()
        .navigationTitle(ficha == nil ? "Sesión terminada" : "\(indice + 1) de \(enCurso.fichas.count)")
    }

    private func tarjeta(_ ficha: Ficha) -> some View {
        VStack(spacing: 24) {
            if let limite = ficha.tiempoMaximoSegundos, !revelada {
                TimelineView(.periodic(from: mostradaEn, by: 1)) { contexto in
                    let quedan = max(0, limite - Int(contexto.date.timeIntervalSince(mostradaEn)))
                    Label("\(quedan) s", systemImage: "timer")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(quedan <= 5 ? .red : .secondary)
                }
            }

            Text(ficha.pregunta)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            if revelada {
                Divider()
                if tiempoAgotado {
                    Label("Se acabó el tiempo", systemImage: "hourglass").foregroundStyle(.orange)
                }
                Text(ficha.respuesta)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                ForEach(ficha.camposAdicionales, id: \.nombre) { campo in
                    LabeledContent(campo.nombre, value: campo.texto).font(.callout)
                }
                Spacer()
                botonesCalificacion(ficha)
            } else {
                Spacer()
                Button("Mostrar respuesta") { revelar(agotado: false) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: 600)
    }

    @ViewBuilder
    private func botonesCalificacion(_ ficha: Ficha) -> some View {
        VStack(spacing: 8) {
            Text("¿Cómo te fue?").font(.headline)
            HStack {
                switch ficha.tipoCalificacion {
                case .escala1a5:
                    ForEach(1...5, id: \.self) { n in
                        Button("\(n)") { calificar(.escala(n)) }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                    }
                case .pasaNoPasa:
                    Button("No pasa") { calificar(.noPasa) }
                        .buttonStyle(.bordered).tint(.red).controlSize(.large)
                    Button("Pasa") { calificar(.pasa) }
                        .buttonStyle(.bordered).tint(.green).controlSize(.large)
                }
            }
        }
    }

    private var terminada: some View {
        ContentUnavailableView("Terminaste por hoy", systemImage: "checkmark.circle",
                               description: Text("Respondiste \(enCurso.sesion.respuestas.count) fichas."))
    }

    /// Si la ficha tiene límite, al cumplirse se revela la respuesta y la respuesta cuenta como tiempo agotado.
    private func esperarLimite(de ficha: Ficha) async {
        guard let limite = ficha.tiempoMaximoSegundos else { return }
        try? await Task.sleep(for: .seconds(limite))
        if !Task.isCancelled && !revelada { revelar(agotado: true) }
    }

    private func revelar(agotado: Bool) {
        tiempoRespuesta = Date.now.timeIntervalSince(mostradaEn)
        tiempoAgotado = agotado
        revelada = true
    }

    private func calificar(_ calificacion: CalificacionOriginal) {
        guard let ficha else { return }
        enCurso.sesion.respuestas.append(Respuesta(
            ficha: ficha, mostradaEn: mostradaEn, calificacion: calificacion,
            tiempoRespuestaSegundos: tiempoRespuesta, tiempoAgotado: tiempoAgotado
        ))
        indice += 1
        mostradaEn = .now
        revelada = false
        tiempoAgotado = false
        if indice == enCurso.fichas.count { enCurso.sesion.terminar(en: .now) }
    }
}
