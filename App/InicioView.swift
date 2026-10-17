import FichasCore
import FichasDatos
import SwiftUI

/// Pantalla de inicio: cuántas fichas tocan hoy y un botón para empezar.
/// Por ahora es un marcador de posición; la lógica vive en FichasCore.
struct InicioView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Fichas para hoy")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("0")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                Button("Empezar") {}
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(true)
            }
            .padding()
            .navigationTitle("Fichas")
            .toolbar {
                NavigationLink {
                    CategoriasView()
                } label: {
                    Label("Categorías", systemImage: "folder")
                }
            }
        }
    }
}

#Preview {
    InicioView()
        .modelContainer(try! Almacen.contenedorEnMemoria())
}
