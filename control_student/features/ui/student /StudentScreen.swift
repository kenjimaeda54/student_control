//
//  Student.swift
//  control_student
//
//  Created by kenjimaeda on 05/03/26.
//

import SwiftUI
import FamilyControls

struct StudentScreen: View {
    @StateObject var manager = StudentShieldManager.shared
    @State private var isPickerPresented = false
    @State private var isSending = false
    @State private var sendError = false
    @State private var showPreview = false
    @State private var appsViewID = UUID()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section(header: Text("Apps de Estudo")) {
                        Button {
                            isPickerPresented = true
                        } label: {
                            HStack {
                                Label("Selecionar Apps", systemImage: "apps.iphone")
                                Spacer()
                                selectionCountBadge
                            }
                        }
                        .disabled(manager.isLessonActive)

                        if !manager.selection.categoryTokens.isEmpty {
                            validationError(
                                title: "Categorias não são permitidas",
                                subtitle: "Abra a categoria e selecione os apps individualmente.",
                                icon: "xmark.octagon.fill",
                                color: .red
                            )
                        }

                        if manager.selection.applicationTokens.count > 3 {
                            validationError(
                                title: "Máximo 3 apps",
                                subtitle: "Você selecionou \(manager.selection.applicationTokens.count). Remova alguns.",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange
                            )
                        }
                    }

                    if !manager.selection.applicationTokens.isEmpty {
                        Section(header: Text("Apps Selecionados")) {
                            ForEach(Array(manager.selection.applicationTokens), id: \.self) { token in
                                Label(token)
                                    .padding(.vertical, 4)
                            }
                        }
                        .id(appsViewID)
                    }
                }

                actionFooter
            }
            .navigationTitle("Configurar Aula")
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $manager.selection
            )
            // sheet de preview/confirmação da foto
            .sheet(isPresented: $showPreview) {
                PreviewPhoto(
                    manager: manager,
                    isSending: $isSending,
                    sentSuccess: .constant(false),
                    showPreview: $showPreview
                ) { screenshot in
                    Task {
                        isSending = true
                        sendError = false
                        let approved = await manager.confirmSelectionApps(screenshot: screenshot)
                        if approved {
                            manager.connectWebSocket()
                            showPreview = false
                            manager.showLessonSheet = true // abre sheet de status
                        } else {
                            sendError = true
                        }
                        isSending = false
                    }
                }
            }
            .sheet(isPresented: $manager.showLessonSheet) {
                LessonStatusSheet(manager: manager)
                    .interactiveDismissDisabled(true) 
            }
        }
        .onAppear {
            Task { await manager.requestAccess() }
        }
    }

    private var actionFooter: some View {
        VStack {
            Divider()

            if sendError {
                Label("Erro ao enviar. Tente novamente.", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }

            Button {
                showPreview = true
            } label: {
                Text(buttonLabel).bold()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(manager.isReadyToConfirm ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(!manager.isReadyToConfirm || isSending)
        }
        .padding()
    }

    private func validationError(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon).foregroundColor(color)
            VStack(alignment: .leading) {
                Text(title).font(.subheadline).bold()
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var selectionCountBadge: some View {
        Text("\(manager.selection.applicationTokens.count)")
            .font(.caption).bold()
            .padding(6)
            .background(manager.isTechnicalSelectionValid ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
            .cornerRadius(6)
    }

    private var buttonLabel: String {
        if manager.selection.applicationTokens.isEmpty { return "Escolha Apps" }
        if !manager.selection.categoryTokens.isEmpty { return "Remova Categorias" }
        if manager.selection.applicationTokens.count > 3 { return "Máximo 3 Apps" }
        return "Enviar para avaliação"
    }
}
