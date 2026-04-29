//
//  StudentState.swift
//  control_student
//
//  Created by kenjimaeda on 28/04/26.
//

import Foundation
internal import Combine
import Network
import ManagedSettings
import FamilyControls

class StudentState: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate {
    @Published var classStart: Bool = false
    @Published var isLockedByProfessor = false
    @Published var teacherIP: String? = nil
    @Published var canExit = false
    @Published var exitRequested = false
    @Published var lessonStarted = false
    @Published var isLessonActive = false
    @Published var familyControlsAuthorized = false
    @Published var networkAuthorized = false
    private var lessonTimerTask: Task<Void, Never>?
    @Published var timeRemaining: Int = 0
    @Published var connectionStatus: String = "Searching for Teacher..."
    private var webSocketTask: URLSessionWebSocketTask?
    private let store = ManagedSettingsStore()
    private var browser: NetServiceBrowser?
    private var service: NetService?
    private var cancellables = Set<AnyCancellable>()
    @Published var selection = FamilyActivitySelection(includeEntireCategory: false) {
        didSet {
            hasConfirmedVisualList = false
        }
    }
    @Published var hasConfirmedVisualList = false
    @Published var showLessonSheet = false

    
    override init() {
        super.init()
        startDiscovery()
    }
    
    func startDiscovery() {
        self.connectionStatus = "Scanning network..."
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_mopiaula._tcp.", inDomain: "local.")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Found Teacher: \(service.name)")
        self.service = service
        self.service?.delegate = self
        self.service?.resolve(withTimeout: 5.0)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        if let data = sender.addresses?.first {
            let ip = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> String? in
                let sockaddr = ptr.bindMemory(to: sockaddr_in.self).baseAddress
                guard let addr = sockaddr?.pointee.sin_addr else { return nil }
                return String(cString: inet_ntoa(addr))
            }
            
            DispatchQueue.main.async {
                self.teacherIP = ip
                self.connectionStatus = "Connected to Teacher"
                self.networkAuthorized = true
                if let ip = ip {
                    self.setupWebSocket(ip: ip)
                }
                self.startStatusPolling()
            }
        }
    }

    private func startStatusPolling() {
        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.fetchStatusWithRetry()
                }
            }
            .store(in: &cancellables)
    }
    
    func setupWebSocket(ip: String) {
            let url = URL(string: "ws://\(ip):8080/wsStatus")!
            webSocketTask = URLSession.shared.webSocketTask(with: url)
            webSocketTask?.resume()
            receiveMessage()
    }
    
    private func receiveMessage() {
            webSocketTask?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        DispatchQueue.main.async {
                            self?.classStart = (text == "true")
                        }
                    default: break
                    }
                    self?.receiveMessage()
                    
                case .failure(let error):
                    print("Erro no WebSocket: \(error)")
                }
            }
        }
    
    func fetchStatusWithRetry(attempts: Int = 3) async {
        guard let ip = teacherIP else { return }
        let url = URL(string: "http://\(ip):8080/status")!
        
        for i in 0..<attempts {
            do {
               
            } catch {
                if i < attempts - 1 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
        
        await MainActor.run {
            self.connectionStatus = "Connection Lost. Retrying..."
        }
    }
    
    func sendStartLesson(studentId: String, durationInSeconds: Int) async {
        await MainActor.run {
            self.startLesson(duration: durationInSeconds)
        }
    }
    
    func updateShieldState() {
        guard isLessonActive else {
            store.clearAllSettings()
            print("🔓 Shield desativado")
            return
        }

        if isLockedByProfessor {
            store.clearAllSettings()
            print("⏸ Apps liberados pelo professor")
        } else {
            // Bloqueia tudo — sem exceções
            store.shield.applicationCategories = .all()
            store.shield.webDomainCategories = .all()
            print("🛡 Bloqueio total ativo")
        }
    }
    
    private func startLessonTimer() {
        lessonTimerTask?.cancel()
        lessonTimerTask = Task {
            while timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { self.timeRemaining -= 1 }
            }
            await MainActor.run { self.stopLesson() }
        }
    }
    
    func sendStopLesson(studentId: String) async {
        // 1. Chamada de API: POST /stop-lesson
        await MainActor.run {
            self.stopLesson()
        }
    }
    
    func stopLesson() {
        isLessonActive = false
        lessonStarted = false
        isLockedByProfessor = false
        canExit = false
        exitRequested = false
        timeRemaining = 0
        showLessonSheet = false
        lessonTimerTask?.cancel()
        updateShieldState()
    }
    
    func requestExit() async {
//        var request = URLRequest(url: URL(string: "https://seubackend.com/request-exit")!)
//        request.httpMethod = "POST"
//        let body = ["student_id": "ID_DO_ALUNO"]
//        request.httpBody = try? JSONEncoder().encode(body)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        try? await URLSession.shared.data(for: request)

        // 🔌 remover simulação quando backend estiver pronto
        print("📤 Solicitação de saída enviada ao backend")
        await MainActor.run { self.exitRequested = true }
    }
    
    func startLesson(duration: Int) {
        isLessonActive = true
        lessonStarted = true
        timeRemaining = duration
        isLockedByProfessor = false
        updateShieldState()
        startLessonTimer()
        print("🎓 Aula iniciada — \(duration)s")
    }
    
    func startLessonWithoutScreenshot() async -> Bool {
        try? await Task.sleep(nanoseconds: 500_000_000)
        await MainActor.run {
            self.hasConfirmedVisualList = true
            self.startLesson(duration: 2700)
        }
        return true
    }
    
    @MainActor
    func requestAccess() async {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                self.familyControlsAuthorized = true
                print("✅ FamilyControls OK")
            } catch {
                self.familyControlsAuthorized = false
                print("❌ FamilyControls Negado")
            }
        }
}
