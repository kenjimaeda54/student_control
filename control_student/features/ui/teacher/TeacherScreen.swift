//
//  TeacherScreen.swift
//  control_student
//
//  Created by kenjimaeda on 05/03/26.
//

import Foundation

import SwiftUI

import SwiftUI
internal import Combine

import SwiftUI
import FamilyControls
//
//struct TeacherScreen: View {
//    @State private var sessionDuration: Double = 45
//    @State private var timeRemaining: Int = 0
//    @State private var isLockActive: Bool = false
//    @State private var studentReady: Bool = false
//    
//    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 25) {
//                HStack {
//                    VStack(alignment: .leading) {
//                        Text("Status da Conexão").font(.caption).foregroundColor(.secondary)
//                        Text(studentReady ? "ALUNO PRONTO" : "AGUARDANDO ALUNO...")
//                            .font(.headline).foregroundColor(studentReady ? .green : .orange)
//                    }
//                    Spacer()
//                    Circle().fill(studentReady ? Color.green : Color.orange).frame(width: 12, height: 12)
//                }
//                .padding().background(Color.secondary.opacity(0.1)).cornerRadius(15)
//
//                VStack {
//                    Text("Duração da Aula").font(.headline)
//                    Text("\(timeRemaining > 0 ? formatTime(timeRemaining) : "\(Int(sessionDuration)) min")")
//                        .font(.system(size: 40, weight: .bold, design: .monospaced))
//                    
//                    Slider(value: $sessionDuration, in: 5...120, step: 5)
//                        .disabled(isLockActive)
//                }.padding()
//
//                VStack(spacing: 15) {
//                    Button(action: { startFocusSession() }) {
//                        Label("Iniciar Aula & Bloquear", systemImage: "lock.fill")
//                            .bold().frame(maxWidth: .infinity).padding().background(studentReady && !isLockActive ? Color.blue : Color.gray).foregroundColor(.white).cornerRadius(12)
//                    }.disabled(!studentReady || isLockActive)
//
//                    Button(action: { cancelSession() }) {
//                        Label("Cancelar / Finalizar", systemImage: "lock.open.fill")
//                            .bold().frame(maxWidth: .infinity).padding().background(isLockActive ? Color.red.opacity(0.1) : Color.clear).foregroundColor(isLockActive ? .red : .gray).cornerRadius(12)
//                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isLockActive ? Color.red : Color.gray))
//                    }.disabled(!isLockActive)
//                }
//                
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("Professor")
//            .onReceive(timer) { _ in
//                if isLockActive && timeRemaining > 0 {
//                    timeRemaining -= 1
//                    if timeRemaining == 0 { cancelSession() }
//                }
//            }
//            .onAppear() {
////                // "Vigie a gaveta chamada status_do_aluno"
////                    BancoDeDados.ouvir("status_do_aluno") { novoValor in
////                        if novoValor == "READY" {
////                            self.studentReady = true  // Isso libera o botão na tela!
////                        } else if novoValor == "WAITING" {
////                            self.studentReady = false // Bloqueia o botão novamente
////                        }
////                    }
////                {
////                  "aula_id_01": {
////                    "status_do_aluno": "READY",
////                    "bloqueio_ativo": false,
////                    "tempo_restante": 45
////                  }
////                }
//            }
//        }
//    }
//
//    func startFocusSession() {
//        isLockActive = true
//        timeRemaining = Int(sessionDuration) * 60
//        
//        StudentShieldManager.shared.activateShield()
//    }
//
//    func cancelSession() {
//        isLockActive = false
//        timeRemaining = 0
//        
//        StudentShieldManager.shared.deactivateShield()
//    }
//    
//    func formatTime(_ seconds: Int) -> String {
//        let m = seconds / 60
//        let s = seconds % 60
//        return String(format: "%02d:%02d", m, s)
//    }
//}
//#Preview {
//    TeacherScreen()
//}
//


import SwiftUI

struct TeacherScreen: View {
    
    @StateObject private var manager = StudentShieldManager.shared
    
    @State private var sessionDuration: Double = 45
    @State private var timeRemaining: Int = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        
        NavigationView {
            
            VStack(spacing: 25) {
                
                connectionStatus
                
                durationControl
                
                controlButtons
                
                Spacer()
            }
            .padding()
            .navigationTitle("Professor")
            .onReceive(timer) { _ in updateTimer() }
        }
    }
    
    var connectionStatus: some View {
        
        HStack {
            
            VStack(alignment: .leading) {
                
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if manager.isSelectionValid {
                    Text("ALUNO PRONTO")
                        .foregroundColor(.green)
                        .bold()
                    
                } else if !manager.selection.applicationTokens.isEmpty {
                    Text("SELEÇÃO INVÁLIDA")
                        .foregroundColor(.red)
                        .bold()
                    
                } else {
                    Text("AGUARDANDO ALUNO")
                        .foregroundColor(.orange)
                        .bold()
                }
            }
            
            Spacer()
            
            Circle()
                .fill(manager.isSelectionValid ? Color.green : Color.orange)
                .frame(width: 12)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    var durationControl: some View {
        
        VStack {
            
            Text("Duração da Aula")
            
            Text(timeRemaining > 0 ? formatTime(timeRemaining) : "\(Int(sessionDuration)) min")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
            
            Slider(value: $sessionDuration, in: 5...120, step: 5)
                .disabled(manager.isLessonActive)
        }
    }
    
    var controlButtons: some View {
        
        VStack(spacing: 15) {
            
            Button {
                startSession()
            } label: {
                Label("Iniciar Aula", systemImage: "lock.fill")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canStart ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canStart)
            
            if manager.isLessonActive {
                
                Button {
                    toggleLock()
                } label: {
                    Label(
                        manager.isLockedByProfessor ? "Retomar Bloqueio" : "Pausar Bloqueio",
                        systemImage: manager.isLockedByProfessor ? "lock.slash" : "lock.open"
                    )
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
            }
            
            Button {
                cancelSession()
            } label: {
                Label("Finalizar Aula", systemImage: "xmark.circle.fill")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.red)
            }
            .disabled(!manager.isLessonActive)
        }
    }
    
    var canStart: Bool {
        manager.isSelectionValid && !manager.isLessonActive
    }
    
    func startSession() {
        timeRemaining = Int(sessionDuration * 60)
        manager.startLesson()
    }
    
    func cancelSession() {
        timeRemaining = 0
        manager.stopLesson()
    }
    
    func toggleLock() {
        manager.setProfessorLock(active: !manager.isLockedByProfessor)
    }
    
    func updateTimer() {
        
        guard manager.isLessonActive else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            cancelSession()
        }
    }
    
    func formatTime(_ s: Int) -> String {
        let m = s / 60
        let s = s % 60
        return String(format: "%02d:%02d", m, s)
    }
}
