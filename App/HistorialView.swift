import FichasDatos
import SwiftData
import SwiftUI

/// Resultados de sesiones anteriores (REQ-030), de la más reciente a la más antigua.
struct HistorialView: View {
    @Query(sort: \Sesion.inicio, order: .reverse) private var sesiones: [Sesion]

    var body: some View {
        List(sesiones) { sesion in
            NavigationLink {
                ResumenView(sesion: sesion)
                    .navigationTitle("Sesión")
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sesion.inicio.formatted(date: .abbreviated, time: .shortened))
                    HStack {
                        Text("\(sesion.respuestas.count) fichas")
                        if sesion.enCurso {
                            // Se salió antes de terminar; quedan las respuestas que alcanzó a dar.
                            Text("· sin terminar").foregroundStyle(.orange)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .overlay {
            if sesiones.isEmpty {
                ContentUnavailableView("Sin sesiones", systemImage: "clock",
                                       description: Text("Aquí aparecen las sesiones que termines."))
            }
        }
        .navigationTitle("Historial")
    }
}
