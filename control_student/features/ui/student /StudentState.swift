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
import CallKit

class StudentState: NSObject, ObservableObject, NetServiceBrowserDelegate, NetServiceDelegate, CXCallObserverDelegate {
    //@Published var classStart: Bool = false
    @Published var isLockedByProfessor = false
    @Published var teacherIP: String? = nil
    @Published var canExit = false
    @Published var lessonStarted = false
    @Published var inputCode: String = ""
    @Published var studentName: String = ""
    @Published var isNameLocked: Bool = false
    @Published var isLoading: Bool = false
    private var uuid: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isLessonActive = false
    @Published var familyControlsAuthorized = false
    @Published var networkAuthorized = false
    private var lessonTimerTask: Task<Void, Never>?
    @Published var timeRemaining: Int = 0
    @Published var connectionStatus: String = "Searching for Teacher..."
    private let callObserver = CXCallObserver()
    @Published var isInCall = false
    private var webSocketTask: URLSessionWebSocketTask?
    private let store = ManagedSettingsStore()
    private var browser: NetServiceBrowser?
    private var withoutNetwork: Bool = false
    private var service: NetService?
    private var cancellables = Set<AnyCancellable>()
    @Published var selection = FamilyActivitySelection(includeEntireCategory: false) {
        didSet {
            hasConfirmedVisualList = false
        }
    }
    @Published var hasConfirmedVisualList = false
    @Published var showLessonSheet = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "AirplaneModeMonitor")

    
    override init() {
        super.init()
        //MARK: - Monitorar  internet
        //startMonitoring()
        startDiscovery()
        callObserver.setDelegate(self, queue: .main)
    }
    
    
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
            if call.hasConnected && !call.hasEnded {
                isInCall = true
                evaluateSecurityState()
                
            } else if call.hasEnded {
                isInCall = false
            }
        }
    
    //MARK: - Monitorar  internet
//    func startMonitoring() {
//            monitor.pathUpdateHandler = { path in
//                DispatchQueue.main.async {
//                    self.evaluatePath(path)
//                }
//            }
//            monitor.start(queue: queue)
//        }
    
    func startDiscovery() {
        self.connectionStatus = "Scanning network..."
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_mopiaula._tcp.", inDomain: "local.")
    }
    
    //MARK: - Montirar interenet
//    private func evaluatePath(_ path: NWPath) {
//        if path.status == .unsatisfied {
//            let hasWifi = path.usesInterfaceType(.wifi)
//            let hasCellular = path.usesInterfaceType(.cellular)
//            let hasEthernet = path.usesInterfaceType(.wiredEthernet)
//            
//            if !hasWifi && !hasCellular && !hasEthernet {
//                withoutNetwork = true
//                onAirplaneModeActivated()
//                evaluateSecurityState()
//            }
//        } else {
//            withoutNetwork = false
//            onAirplaneModeDeactivated()
//        }
//    }
//    
    
    private func reportarAlert(tipo: String) {
        guard let ip = teacherIP else {
            saveAlertTeacher(tipo: tipo)
            return
        }
        
        let payload: [String: Any] = [
            "tipo": tipo,
            "timestamp": Date().ISO8601Format(),
            "em_ligacao": isInCall,
            "sem_rede": withoutNetwork,
            "duracao_aula": timeRemaining
        ]
        
        // Envia para o professor via WebSocket (já tem setup)
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let text = String(data: data, encoding: .utf8) {
        }
    }
    
    private func saveAlertTeacher(tipo: String) {
        var log = ConnectionStorage.load()
        log.lastDisconnected = Date()
        ConnectionStorage.save(log)
    }

    
    private func evaluateSecurityState() {
        guard isLessonActive else { return }
        
        switch (withoutNetwork, isInCall) {
            
        case (true, true):
            reportarAlert(tipo: "call_without_network")
            
        case (false, true):
            reportarAlert(tipo: "call_during_lesson")
            
        case (true, false):
            print("📴 Sem rede — aguardando...")
            
        case (false, false):
            print("✅ Situação normal")
        }
    }
    
    private func onAirplaneModeActivated() {
        var log = ConnectionStorage.load()
           log.lastConnected = Date()
           ConnectionStorage.save(log)
           reportToServer(log: log)
    }
    
    
    private func onAirplaneModeDeactivated() {
        var log = ConnectionStorage.load()
        
        guard let disconnected = log.lastDisconnected else {
            return
        }
        
        log.lastConnected = Date()
        ConnectionStorage.save(log)
        reportToServer(log: log)
        ConnectionStorage.clear()
    }
    
    private func reportToServer(log: ConnectionLog) {
        guard let connected = log.lastConnected,
              let disconnected = log.lastDisconnected else { return }
        
        let payload: [String: Any] = [
            "last_connected": connected.ISO8601Format(),
            "last_disconnected": disconnected.ISO8601Format(),
        ]
        
    }


    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
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
    }
    
    
    func fetchStatusWithRetry(attempts: Int = 3) async {
        guard let ip = teacherIP else { return }
        let url = URL(string: "http://\(ip):8080/status")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let session = URLSession(configuration: config)
        
        for i in 0..<attempts {
            do {
                let (data, response) = try await session.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                await MainActor.run {
                    self.connectionStatus = "Connected to Teacher"
                }
                return
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
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
            print("🔓 Shield desativado")
            return
        }

        if isLockedByProfessor {
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
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
        await MainActor.run {
            self.stopLesson()
        }
    }
    
    func stopLesson() {
        isLessonActive = false
        lessonStarted = false
        isLockedByProfessor = false
        canExit = false
        timeRemaining = 0
        showLessonSheet = false
        lessonTimerTask?.cancel()
        updateShieldState()
    }
    
    func startLesson(duration: Int) {
        isLessonActive = true
        lessonStarted = true
        timeRemaining = duration
        isLockedByProfessor = false
        updateShieldState()
        startLessonTimer()
    }

    func notifyTeacherLessonStarted() async {
        guard let ip = teacherIP, let studentUUID = uuid else { return }
        let url = URL(string: "http://\(ip):8080/update-status")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["uuid": studentUUID, "status": "Aula Iniciada"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let duration = json["duracao"] as? Int {
                await MainActor.run {
                    self.startLesson(duration: duration)
                }
            }
        } catch {
            print("Erro ao notificar início de aula: \(error)")
        }
    }
    
    func startLessonWithoutScreenshot() async -> Bool {
        await MainActor.run { 
            self.errorMessage = nil 
            self.isLoading = true
        }
        
        defer {
            DispatchQueue.main.async { self.isLoading = false }
        }
        
        let ip = teacherIP ?? ""
        if ip.isEmpty || ip == "0.0.0.0" {
            await MainActor.run {
                self.errorMessage = "Professor não encontrado. Verifique se a aula foi iniciada e tente novamente."
                self.startDiscovery() 
            }
            return false
        }
        
        guard !studentName.isEmpty && !inputCode.isEmpty else { return false }
        
        let url = URL(string: "http://\(ip):8080/join")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)
        
        if uuid == nil {
            uuid = UUID().uuidString
        }
        
        let payload = ["nome": studentName, "codigo": inputCode, "uuid": uuid ?? ""]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (data, response) = try await session.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                
                if status == "success" && httpResponse?.statusCode == 200 {
                    await MainActor.run {
                        self.isNameLocked = true
                        self.hasConfirmedVisualList = true
                        self.errorMessage = nil
                    }
                    return true
                } else {
                    await MainActor.run {
                        self.errorMessage = status 
                        self.isNameLocked = true 
                    }
                    return false
                }
            }
            
            await MainActor.run { self.errorMessage = "Resposta inválida do servidor" }
            return false
            
        } catch {
            await MainActor.run { 
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.errorMessage = "Tempo esgotado: Verifique se o professor iniciou a aula"
                } else {
                    self.errorMessage = "Erro de conexão com o servidor"
                }
            }
            print("Erro ao validar entrada na aula: \(error)")
            return false
        }
    }
    
    @MainActor
    func triggerLocalNetworkPrivacyAlert() {
        // Disparar uma busca mDNS ou um ping simples costuma forçar o alerta do iOS
        startDiscovery()
        
        // Tentar um fetch rápido para garantir o gatilho
        Task {
            let _ = try? await URLSession.shared.data(from: URL(string: "http://255.255.255.255")!)
        }
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
