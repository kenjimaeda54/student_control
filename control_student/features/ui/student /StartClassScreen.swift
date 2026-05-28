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
        @State private var inputValue = ""
        @State private var isInvalidName: Bool = true
        @FocusState private var focusedField: Field?

        enum Field {
            case name
            case code
        }

        
        var canProceed: Bool {
            manager.familyControlsAuthorized &&
            manager.teacherIP != nil &&
            !manager.studentName.isEmpty &&
            !manager.inputCode.isEmpty
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
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seu Nome")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        TextField("Digite seu nome", text: $manager.studentName)
                            .focused($focusedField, equals: .name)
                            .disabled(manager.isNameLocked)
                            .submitLabel(.next)
                            .onSubmit {
                                if !manager.studentName.isEmpty {
                                    manager.isNameLocked = true
                                    focusedField = .code
                                }
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
                            )
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Código da Aula")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        TextField("Digite o código aqui", text: $manager.inputCode)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .focused($focusedField, equals: .code)
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(manager.errorMessage != nil ? Color.red.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1.5)
                            )
                            .padding(.horizontal)
                        
                        if let error = manager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    }
                    
                        
                        Text("O botão abaixo será habilitado assim que todos os itens estiverem corretos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        
                        Spacer()
                        
                        Button {
                            Task {
                                let success = await manager.startLessonWithoutScreenshot()
                                if success {
                                    showMainScreen = true
                                }
                            }
                        } label: {
                            HStack {
                                if manager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 8)
                                }
                                Text(canProceed ? (manager.isLoading ? "Validando..." : "Entrar na Aula") : "Aguardando Requisitos...")
                                    .bold()
                            }
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
                }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                      focusedField = .name
                  }
            }
        }
    }
        private func statusRow(text: String, isOk: Bool) -> some View {
            HStack {
                Image(systemName: isOk ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOk ? .green : .gray)
                Text(text)
                    .foregroundColor(isOk ? .primary : .secondary)
                Spacer()
                if !isOk {
                    if text.contains("Parental") {
                        Button("Autorizar") {
                            Task { await manager.requestAccess() }
                        }
                        .font(.caption)
                    } else if text.contains("Rede Local") {
                        Button("Autorizar") {
                            manager.triggerLocalNetworkPrivacyAlert()
                        }
                        .font(.caption)
                    }
                }
            }
        }
}
