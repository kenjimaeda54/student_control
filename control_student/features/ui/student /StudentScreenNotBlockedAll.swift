
import SwiftUI
import FamilyControls
import PhotosUI

struct StudentScreenNotBlockedAll: View {
    @StateObject var manager = StudentShieldManagerBlockNotAll.shared
    @State private var isPickerPresented = false
    @State private var selectedItems: [PhotosPickerItem] = [] // Para gerenciar a seleção múltipla
    

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        recommendationCard
                        
                        categoryPickerButton
                        
                        if manager.isTechnicalSelectionValid {
                            selectedItemsSummary
                        }

                        // ÁREA DE UPLOAD ÚNICA (MULTI-SELEÇÃO)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Comprovação Visual").font(.headline)
                            Text("Selecione os prints que comprovam o bloqueio das categorias citadas acima.")
                                .font(.caption).foregroundColor(.secondary)
                            
                            multiPhotosPicker
                        }
                    }
                    .padding(20)
                }
                actionFooter
            }
            .navigationTitle("Modo Foco")
            .sheet(isPresented: $manager.showLessonSheet) {
                 VerificationSheet(manager: manager)
            }
            .onAppear {
                    Task { await manager.requestAccess() }
                }
        }
    }

    // MARK: - Componentes de UI

    private var multiPhotosPicker: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 10, // Permite múltiplas fotos
                matching: .images
            ) {
                VStack(spacing: 12) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 40))
                    Text(selectedItems.isEmpty ? "Selecionar Prints de Bloqueio" : "\(selectedItems.count) Prints Selecionados")
                        .font(.headline)
                    Text("Toque para escolher todas as fotos de uma vez")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                )
            }
            .onChange(of: selectedItems) { _ in
                handleMultiImageSelection()
            }

            // Preview das fotos selecionadas
            if !manager.verificationImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(manager.verificationImages, id: \.self) { img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 120)
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.slash.fill").font(.largeTitle).foregroundColor(.red)
            Text("Configurar Restrições").font(.title2.bold())
            Text("Bloqueie as distrações antes de começar.").font(.subheadline).foregroundColor(.secondary)
        }
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Recomendações", systemImage: "lightbulb.fill")
                .foregroundColor(.orange).bold()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Redes Sociais").font(.system(size: 14))
                Text("• Entretenimento (YouTube/Netflix)").font(.system(size: 14))
                Text("• Jogos").font(.system(size: 14))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var categoryPickerButton: some View {
        Button(action: { isPickerPresented = true }) {
            Label(manager.isTechnicalSelectionValid ? "Alterar Bloqueios" : "Selecionar Apps para Bloquear", systemImage: "plus.circle.fill")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(manager.isTechnicalSelectionValid ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                .foregroundColor(manager.isTechnicalSelectionValid ? .blue : .red)
                .cornerRadius(12)
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $manager.selection)
    }

    private var selectedItemsSummary: some View {
        HStack {
            Image(systemName: "lock.fill").foregroundColor(.red)
            Text("\(manager.selection.categoryTokens.count + manager.selection.applicationTokens.count) itens bloqueados")
                .font(.subheadline).bold()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var actionFooter: some View {
        VStack(spacing: 12) {
            Divider()
            Button {
                manager.startPreLessonPhase()
                manager.showLessonSheet = true
                manager.updateShieldState()
            } label: {
                Text("Confirmar Bloqueio e Iniciar").bold().frame(maxWidth: .infinity).padding()
            }
            .background((manager.isTechnicalSelectionValid && !manager.verificationImages.isEmpty) ? Color.red : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!manager.isTechnicalSelectionValid || manager.verificationImages.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Lógica de Seleção

    private func handleMultiImageSelection() {
        Task {
            var loadedImages: [UIImage] = []
            for item in selectedItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            }
            await MainActor.run {
                manager.verificationImages = loadedImages
            }
        }
    }
}
