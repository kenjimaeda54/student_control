//
//  StartClassScreen.swift
//  control_student
//
//  Created by kenjimaeda on 29/04/26.
//

import Foundation
import SwiftUI

struct StartClassScreen: View {
    @StateObject var manager = StudentState()
        @State private var showMainScreen = false
        
        var canProceed: Bool {
            manager.familyControlsAuthorized &&
            manager.teacherIP != nil &&
            manager.classStart
        }
        
        var body: some View {
            if showMainScreen {
                StudentScreen(manager: manager)
            } else {
                VStack(spacing: 25) {
                    Text("Configurando Acesso")
                        .font(.title2).bold()

                    VStack(alignment: .leading, spacing: 15) {
                        statusRow(text: "Permissão de Controle Parental", isOk: manager.familyControlsAuthorized)
                        statusRow(text: "Conexão com a Rede Local", isOk: manager.teacherIP != nil)
                        statusRow(text: "Liberação do Professor", isOk: manager.classStart)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Text("O botão abaixo será habilitado assim que todos os itens acima estiverem verdes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    Button {
                        showMainScreen = true
                    } label: {
                        Text(canProceed ? "Entrar na Aula" : "Aguardando Requisitos...")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(canProceed ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(canProceed ? .white : .secondary)
                    .cornerRadius(12)
                    .disabled(!canProceed) 
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }

        // Helper view para as linhas do check-list
        private func statusRow(text: String, isOk: Bool) -> some View {
            HStack {
                Image(systemName: isOk ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOk ? .green : .gray)
                Text(text)
                    .foregroundColor(isOk ? .primary : .secondary)
                Spacer()
                if !isOk && text.contains("Parental") {
                    Button("Autorizar") {
                        Task { await manager.requestAccess() }
                    }
                    .font(.caption)
                }
            }
        }
}
