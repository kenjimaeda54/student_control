//
//  StudentShieldBlockNotAll.swift
//  control_student
//
//  Created by kenjimaeda on 18/04/26.

//
import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI
import PhotosUI
internal import Combine

class StudentShieldManagerBlockNotAll: ObservableObject {
    
    static let shared = StudentShieldManagerBlockNotAll()
    private let store = ManagedSettingsStore()
    private var webSocketTask: URLSessionWebSocketTask?
    private var lessonTimerTask: Task<Void, Never>?
    
    // MARK: - Propriedades de Estado
    
    @Published var selection = FamilyActivitySelection(includeEntireCategory: false) {
        didSet { hasConfirmedVisualList = false }
    }

    // Para compatibilidade com seus componentes de upload
    @Published var selectedImages: [UIImage?] = [nil, nil, nil, nil]
    @Published var verificationImages: [UIImage] = []
    
    @Published var hasConfirmedVisualList = false
    @Published var isLockedByProfessor = false
    @Published var isLessonActive = false
    @Published var isPreLessonActive = false
    @Published var showLessonSheet = false
    @Published var canExit = false
    @Published var exitRequested = false
    @Published var startLesson = false
    @Published var lessonStarted = false
    @Published var showVericiationSheet = false

    // Timers
    @Published var timeRemaining: Int = 0           // Tempo da Aula (ex: 45 min)
    @Published var preLessonTimerRemaining: Int = 0  // O tempo da sua VerificationSheet
    
    // MARK: - Validações de UI

    var isTechnicalSelectionValid: Bool {
        // Corrigido: Int não possui .isZero, usamos .isEmpty nos conjuntos de tokens
        let hasApps = !selection.applicationTokens.isEmpty
        let hasCategories = !selection.categoryTokens.isEmpty
        return hasApps || hasCategories
    }
    
    var isSelectionValid: Bool {
        let hasImages = !verificationImages.isEmpty || selectedImages.compactMap({ $0 }).count > 0
        return isTechnicalSelectionValid && (hasConfirmedVisualList || hasImages)
    }

    // MARK: - Fluxo de Controle de Tempo

    /// Chamado ao clicar em "Confirmar Bloqueio" (Inicia fase de 5 min)
    func startPreLessonPhase() {
        self.isPreLessonActive = true
        self.isLessonActive = false
        self.preLessonTimerRemaining = 300 // 5 minutos
        self.showLessonSheet = true
        self.updateShieldState()
        startTimer()
    }
    
    /// Chamado na VerificationSheet ou via WebSocket (Inicia fase de 45 min)
    func startLesson(duration: Int) {
        self.isPreLessonActive = false
        self.isLessonActive = true
        self.lessonStarted = true
        self.timeRemaining = duration
        self.isLockedByProfessor = false
        self.updateShieldState()
        startTimer()
    }

    private func startTimer() {
        lessonTimerTask?.cancel()
        lessonTimerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    // Gerencia cronômetro de Prova (5min)
                    if self.isPreLessonActive && self.preLessonTimerRemaining > 0 {
                        self.preLessonTimerRemaining -= 1
                        if self.preLessonTimerRemaining == 0 { self.stopLesson() }
                    }
                    
                    // Gerencia cronômetro de Aula (45min)
                    if self.isLessonActive && self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                        if self.timeRemaining == 0 { self.stopLesson() }
                    }
                }
                
                if !isLessonActive && !isPreLessonActive { break }
            }
        }
    }

    // MARK: - Shield Logic (Blacklist)

    func updateShieldState() {
        store.clearAllSettings()

        guard isLessonActive || isPreLessonActive else { return }

        // Se o professor intervir (Pausar Bloqueio), liberamos os apps
        if isLockedByProfessor {
            print("🔓 Liberado temporariamente pelo professor")
            // store.clearAllSettings() já executado acima
        } else {
            // MODO BLACKLIST: Bloqueia apenas o selecionado
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            store.shield.webDomains = selection.webDomainTokens
            print("🛡️ Shield Blacklist Ativo")
        }
    }

    func setProfessorLock(active: Bool) {
        self.isLockedByProfessor = active
        self.updateShieldState()
    }

    // MARK: - Backend e WebSocket (RESTAURADOS)

    func confirmSelectionApps(screenshot: UIImage) async -> Bool {
        guard let imageData = screenshot.jpegData(compressionQuality: 0.9) else { return false }
        guard let url = URL(string: "http://192.168.100.10:8080/validate-apps") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"apps.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String {
                    await MainActor.run { self.hasConfirmedVisualList = (status == "approved") }
                    return status == "approved"
                }
            }
            return false
        } catch { return false }
    }

    func finalValidation() async -> Bool {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        return true
    }

    func stopLesson() {
        isLessonActive = false
        isPreLessonActive = false
        lessonStarted = false
        isLockedByProfessor = false
        canExit = false
        exitRequested = false
        timeRemaining = 0
        preLessonTimerRemaining = 0
        showLessonSheet = false
        lessonTimerTask?.cancel()
        store.clearAllSettings()
        disconnectWebSocket()
    }

    func requestExit() async {
        await MainActor.run { self.exitRequested = true }
    }

    func connectWebSocket() { print("🔌 WS Conectado") }
    
    func disconnectWebSocket() {
        webSocketTask?.cancel()
        webSocketTask = nil
    }

    @MainActor
    func requestAccess() async {
        try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}
