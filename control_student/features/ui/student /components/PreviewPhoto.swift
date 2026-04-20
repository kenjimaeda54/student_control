//
//  PreviewPhoto.swift
//  control_student
//
//  Created by kenjimaeda on 14/03/26.
//



import ScreenshotSwiftUI

import ScreenshotSwiftUI
import SwiftUI
import FamilyControls
import ManagedSettings


struct PreviewPhoto: View {
    @ObservedObject var manager: StudentShieldManagerBlockNotAll
    @Binding var isSending: Bool
    @Binding var sentSuccess: Bool
    @Binding var showPreview: Bool
    let onConfirm: (UIImage) -> Void
    
    @State private var screenshotMaker: ScreenshotMaker?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // ✅ screenshotMaker na VStack, captura tudo incluindo a lista
                appsListView
                    .screenshotMaker { maker in
                        screenshotMaker = maker
                    }
                
                footerView
            }
            .navigationTitle("Prévia")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // ✅ View separada — mais limpa e fácil de debugar
    private var appsListView: some View {
        let tokens = manager.selection.applicationTokens

        return List {
            Section(header: Text("Apps Selecionados")) {
                ForEach(tokens.sorted(by: { _ , _ in true }), id: \.self) { token in
                    Label(token)
                          .padding(.vertical, 4)
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var footerView: some View {
        VStack {
            Divider()
            
            Text("Essa imagem será enviada para aprovação.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Button {
                // ✅ sem DispatchQueue — captura imediata após tap
                if let image = screenshotMaker?.screenshot() {
                    onConfirm(image)
                }
            } label: {
                if isSending {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Label("Confirmar e Enviar", systemImage: "paperplane.fill")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isSending)
            
            Button("Cancelar") {
                showPreview = false
            }
            .foregroundColor(.secondary)
            .padding(.top, 4)
        }
        .padding()
    }
    
    // ✅ helper para índice legível
    private func appIndex(_ token: ApplicationToken) -> Int {
        (Array(manager.selection.applicationTokens).firstIndex(of: token) ?? 0) + 1
    }
}
