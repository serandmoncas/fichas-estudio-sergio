import FichasCore
import FichasDatos
import SwiftData
import SwiftUI

/// Crear o editar una ficha. Los cambios se guardan solo al tocar "Guardar".
struct FichaFormView: View {
    enum Modo: Identifiable {
        case nueva(Categoria)
        case editar(Ficha)

        var id: PersistentIdentifier {
            switch self {
            case .nueva(let categoria): categoria.persistentModelID
            case .editar(let ficha): ficha.persistentModelID
            }
        }
    }

    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @Query(sort: \Categoria.nombre) private var categorias: [Categoria]

    let modo: Modo

    @State private var pregunta = ""
    @State private var respuesta = ""
    @State private var categoria: Categoria
    @State private var subcategoria: Subcategoria?
    @State private var tipoCalificacion: TipoCalificacion = .escala1a5
    @State private var conTiempo = false
    @State private var segundos = 30
    @State private var camposAdicionales: [CampoAdicional] = []

    init(modo: Modo) {
        self.modo = modo
        switch modo {
        case .nueva(let categoria):
            _categoria = State(initialValue: categoria)
        case .editar(let ficha):
            // categoria siempre tiene valor (REQ-014); ver Ficha.categoria.
            _categoria = State(initialValue: ficha.categoria!)
            _pregunta = State(initialValue: ficha.pregunta)
            _respuesta = State(initialValue: ficha.respuesta)
            _subcategoria = State(initialValue: ficha.subcategoria)
            _tipoCalificacion = State(initialValue: ficha.tipoCalificacion)
            _conTiempo = State(initialValue: ficha.conTiempo)
            _segundos = State(initialValue: ficha.tiempoMaximoSegundos ?? 30)
            _camposAdicionales = State(initialValue: ficha.camposAdicionales)
        }
    }

    private var completa: Bool {
        !pregunta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !respuesta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ficha") {
                    TextField("Pregunta", text: $pregunta, axis: .vertical)
                    TextField("Respuesta", text: $respuesta, axis: .vertical)
                }

                Section("Ubicación") {
                    // Cambiar de categoría es "mover" la ficha: pierde la subcategoría (Ficha.mover(a:)).
                    Picker("Categoría", selection: $categoria) {
                        ForEach(categorias) { Text($0.nombre).tag($0) }
                    }
                    .onChange(of: categoria) { subcategoria = nil }
                    Picker("Subcategoría", selection: $subcategoria) {
                        Text("Ninguna").tag(Subcategoria?.none)
                        ForEach(categoria.subcategorias) { Text($0.nombre).tag(Optional($0)) }
                    }
                }

                Section("Estudio") {
                    Picker("Calificación", selection: $tipoCalificacion) {
                        Text("Escala 1 a 5").tag(TipoCalificacion.escala1a5)
                        Text("Pasa / No pasa").tag(TipoCalificacion.pasaNoPasa)
                    }
                    Toggle("Límite de tiempo", isOn: $conTiempo)
                    if conTiempo {
                        Stepper("\(segundos) segundos", value: $segundos, in: 5...600, step: 5)
                    }
                }

                Section {
                    ForEach(camposAdicionales.indices, id: \.self) { i in
                        TextField("Nombre", text: $camposAdicionales[i].nombre)
                        TextField("Texto", text: $camposAdicionales[i].texto, axis: .vertical)
                    }
                    .onDelete { camposAdicionales.remove(atOffsets: $0) }
                    Button("Agregar campo", systemImage: "plus") {
                        camposAdicionales.append(CampoAdicional(nombre: "", texto: ""))
                    }
                } header: {
                    Text("Campos adicionales")
                } footer: {
                    Text("Por ejemplo, una pista o un ejemplo.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(esNueva ? "Nueva ficha" : "Editar ficha")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }.disabled(!completa)
                }
            }
        }
    }

    private var esNueva: Bool {
        if case .nueva = modo { true } else { false }
    }

    private func guardar() {
        let campos = camposAdicionales.filter { !$0.nombre.isEmpty || !$0.texto.isEmpty }
        let tiempo = conTiempo ? segundos : nil
        do {
            switch modo {
            case .nueva:
                contexto.insert(try Ficha(pregunta: pregunta, respuesta: respuesta, categoria: categoria,
                                          subcategoria: subcategoria, camposAdicionales: campos,
                                          tipoCalificacion: tipoCalificacion, tiempoMaximoSegundos: tiempo))
            case .editar(let ficha):
                ficha.pregunta = pregunta
                ficha.respuesta = respuesta
                ficha.mover(a: categoria)
                try ficha.asignar(subcategoria: subcategoria)
                ficha.tipoCalificacion = tipoCalificacion
                ficha.tiempoMaximoSegundos = tiempo
                ficha.camposAdicionales = campos
            }
            cerrar()
        } catch {
            // El selector solo ofrece subcategorías de la categoría elegida, así que no debería pasar.
            assertionFailure("No se pudo guardar la ficha: \(error)")
        }
    }
}
