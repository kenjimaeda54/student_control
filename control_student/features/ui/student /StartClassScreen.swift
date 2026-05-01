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
        @State private var inputText: String = ""
        @State private var isInvalidCode: Bool = true
        @FocusState private var isCodeFieldFocused: Bool

        
        var canProceed: Bool {
            manager.familyControlsAuthorized &&
            manager.teacherIP != nil &&
            isInvalidCode == false
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Código da Aula")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {

                            TextField("Digite o código aqui", text: $inputText)
                                .textFieldStyle(.plain)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($isCodeFieldFocused)

                            if !inputText.isEmpty {
                                Button {
                                    isInvalidCode = manager.handleInvalidateCode(value: inputText)
                                } label: {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(isInvalidCode ? .red : .blue)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isInvalidCode && !inputText.isEmpty ? Color.red : Color.gray.opacity(0.2), lineWidth: 1.5)
                        )
                        
                        if isInvalidCode && !inputText.isEmpty {
                            Text("Digite corretamente o token fornecido pelo professor")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal)
                    .animation(.default, value: isInvalidCode)
                    .animation(.default, value: inputText) // Anima a entrada da seta
                        
                        Text("O botão abaixo será habilitado assim que todos os itens estiverm correto")
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
                }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                      isCodeFieldFocused = true
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
                if !isOk && text.contains("Parental") {
                    Button("Autorizar") {
                        Task { await manager.requestAccess() }
                    }
                    .font(.caption)
                }
            }
        }
}
