//
//  XcodeListener.swift
//  CursorSwitcher
//
//  Created by Tyler Yust on 1/29/25.
//

//
//  XcodeListener.swift
//  CursorSwitcher
//
//  Created by Tyler Yust on 1/29/25.
//

import Foundation
import Network
import AppKit

class XcodeFileListener {
    // MARK: - Properties
    
    let port: NWEndpoint.Port = 8124
    private var listener: NWListener?
    private var projectRoot: URL?
    private var connections: [UUID: NWConnection] = [:]
    
    private var viewModel: ViewModel
    
    private let queue = DispatchQueue(label: "com.tyleryust.xcursor.listener")
    
    // Heartbeat
    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 30.0  // e.g. 30 seconds
    private var lastHeartbeatResponse: Date = Date()
    private let heartbeatTimeout: TimeInterval = 60.0   // e.g. 60 seconds
    
    // We only shut down if explicitly called:
    private var isShuttingDown = false
    
    // MARK: - Init
    
    init(projectRoot: URL, viewModel: ViewModel) {
        self.projectRoot = projectRoot
        self.viewModel = viewModel
        
        createListener()
        start()
        startHeartbeat()
    }
    
    // MARK: - Create & Start Listener
    
    private func createListener() {
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            parameters.allowFastOpen = true
            
            // Enable TCP keepalive
            if let tcpOptions = parameters.defaultProtocolStack.internetProtocol as? NWProtocolTCP.Options {
                tcpOptions.enableKeepalive = true
                tcpOptions.keepaliveIdle = 5      // seconds before keep-alive probes start
                tcpOptions.keepaliveCount = 5     // number of keep-alive probes
                tcpOptions.keepaliveInterval = 2  // seconds between keep-alive probes
            }
            
            self.listener = try NWListener(using: parameters, on: port)
            print("🚀 XcodeListener created on port \(port)")
        } catch {
            print("❌ Unable to create listener: \(error)")
            // Normally, you might decide to retry after a delay. But we do NOT
            // auto-reconnect in this version—if it fails here, you must fix the port conflict or error.
        }
    }
    
    func start() {
        guard let listener = listener else {
            print("⚠️ No listener available, skipping start.")
            return
        }
        
        isShuttingDown = false
        
        // Update the listener's state in real time
        listener.stateUpdateHandler = { [weak self] newState in
            guard let self = self, !self.isShuttingDown else { return }
            
            self.queue.async {
                switch newState {
                case .ready:
                    print("✅ XCursor is running on port \(self.port)")
                    // We don't set isConnected = true here, because that depends on actual NWConnections.
                case .failed(let error):
                    // This usually means a fatal error (e.g. port is in use).
                    print("❌ XCursor connection failed: \(error)")
                    // In this simplified version, we do NOT automatically restart.
                case .cancelled:
                    print("❌ XCursor connection cancelled")
                default:
                    break
                }
            }
        }
        
        // Accept new incoming connections
        listener.newConnectionHandler = { [weak self] connection in
            guard let self = self, !self.isShuttingDown else { return }
            
            self.queue.async {
                let connectionId = UUID()
                self.connections[connectionId] = connection
                
                // Monitor each connection's state
                connection.stateUpdateHandler = { [weak self] state in
                    guard let self = self else { return }
                    
                    self.queue.async {
                        switch state {
                        case .ready:
                            // Mark that we have at least one active connection
                            self.updateViewModelConnectionStatus()
                            print("🔗 New connection ready (\(connectionId))")
                        case .failed, .cancelled:
                            print("🔌 Connection \(connectionId) ended: \(state)")
                            self.connections.removeValue(forKey: connectionId)
                            self.updateViewModelConnectionStatus()
                        default:
                            break
                        }
                    }
                }
                
                // Start the connection
                connection.start(queue: self.queue)
                
                // Begin receiving data
                self.receive(on: connection)
            }
        }
        
        // Start listening
        listener.start(queue: queue)
    }
    
    // MARK: - Heartbeat
    
    private func startHeartbeat() {
        stopHeartbeat() // in case it's somehow running already
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: self.heartbeatInterval, repeats: true) { [weak self] _ in
                guard let self = self, !self.isShuttingDown else { return }
                
                // Send a heartbeat to any active connections
                if self.connections.isEmpty {
                    // No active connections. You can log something or do nothing.
                    // We do NOT attempt any "reconnect" logic here.
                    // print("ℹ️ No active connections; still listening…")
                } else {
                    // Send heartbeat to existing connections
                    self.connections.values.forEach { connection in
                        self.sendHeartbeat(on: connection)
                    }
                }
            }
        }
    }
    
    private func stopHeartbeat() {
        DispatchQueue.main.async { [weak self] in
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = nil
        }
    }
    
    private func sendHeartbeat(on connection: NWConnection) {
        let heartbeat = "heartbeat".data(using: .utf8)!
        connection.send(content: heartbeat, completion: .contentProcessed { error in
            if let error = error {
                print("⚠️ Heartbeat send failed: \(error)")
            }
        })
    }
    
    // MARK: - Receiving Data
    
    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1,
                           maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = data {
                if let message = String(data: data, encoding: .utf8) {
                    if message == "heartbeat" {
                        self.lastHeartbeatResponse = Date()
                        // You might log or track that you got a heartbeat from the client
                    } else {
                        // Handle normal file path messages
                        self.handleMessage(message)
                    }
                }
            }
            
            if let error = error {
                print("❌ Receive error: \(error)")
                // The connection may or may not close immediately after this error.
            }
            
            // Keep reading if there's more data coming
            if !isComplete {
                self.receive(on: connection)
            }
        }
    }
    
    // MARK: - Handling Incoming Messages
    
    private func handleMessage(_ message: String) {
        print("Message Received")
        
        // Try parsing as JSON first
        if let data = message.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let filePath = dict["path"] {
            
            handleFilePath(filePath)
            
        } else {
            // Otherwise, treat the message as a plain file path
            let filePath = message.trimmingCharacters(in: .whitespacesAndNewlines)
            handleFilePath(filePath)
        }
    }
    
    private func handleFilePath(_ filePath: String) {
        // Remove any .git extension that might be incorrectly appended
        let cleanPath = filePath.replacingOccurrences(of: ".git", with: "")
        let fileURL = URL(fileURLWithPath: cleanPath)
        
        // Verify if the file is inside the allowed root folder
        if let projectRoot = projectRoot {
            let normalizedFilePath = fileURL.standardizedFileURL.path
            let normalizedRootPath = projectRoot.standardizedFileURL.path
            
            if normalizedFilePath.hasPrefix(normalizedRootPath) {
                openInXcode(path: cleanPath)
            } else {
                print("🛑 File is outside the allowed project folder")
                print("File path: \(normalizedFilePath)")
                print("Root path: \(normalizedRootPath)")
            }
        } else {
            print("⚠️ No project root set")
        }
    }
    
    private func doesFileContainPreview(path: String) -> Bool {
        guard let projectRoot = projectRoot else {
            print("⚠️ No project root set")
            return false
        }
        
        // Access the security-scoped resource if needed (for sandboxed apps)
        guard projectRoot.startAccessingSecurityScopedResource() else {
            print("❌ Failed to access security-scoped resource")
            return false
        }
        defer {
            projectRoot.stopAccessingSecurityScopedResource()
        }
        
        // Try to read the file contents
        do {
            let fileContent = try String(contentsOfFile: path, encoding: .utf8)
            return fileContent.contains("#Preview") || fileContent.contains("PreviewProvider")
        } catch {
            print("❌ Failed to read file: \(error)")
            return false
        }
    }
    
    /// Opens the file in Xcode **only if** it contains a SwiftUI Preview.
    private func openInXcode(path: String) {
        let fileHasPreview = doesFileContainPreview(path: path)
        print("File '\(path)' \(fileHasPreview ? "contains" : "does NOT contain") a SwiftUI preview.")
        
        // If the file doesn't contain a preview, do nothing
        guard fileHasPreview else {
            return
        }
        
        // Locate Xcode by its bundle identifier
        guard let xcodeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.dt.Xcode") else {
            print("❌ Xcode not found on the system.")
            return
        }
        
        let fileURL = URL(fileURLWithPath: path)
        
        // Open the file in Xcode without bringing it to the foreground
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false  // Ensures Xcode does NOT become active
        
        NSWorkspace.shared.open([fileURL], withApplicationAt: xcodeURL,
                                configuration: config, completionHandler: nil)
        
        print("✅ Successfully opened file in Xcode (in background): \(path)")
    }
    
    // MARK: - Project Root Updates
    
    func updateProjectRoot(_ newRoot: URL) {
        self.projectRoot = newRoot
        print("📂 Updated project root to: \(newRoot.path)")
    }
    
    // MARK: - Shutdown
    
    func shutdown() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.isShuttingDown = true
            
            // Stop heartbeats
            self.stopHeartbeat()
            
            // Cancel any active connections
            self.cleanupConnections()
            
            // Finally cancel the listener
            self.listener?.cancel()
            self.listener = nil
        }
    }
    
    private func cleanupConnections() {
        connections.values.forEach { $0.cancel() }
        connections.removeAll()
    }
    
    // MARK: - View Model Updates
    
    /// Updates `viewModel.isConnected` based on whether we have any active connections.
    private func updateViewModelConnectionStatus() {
        let currentlyConnected = !connections.isEmpty
        DispatchQueue.main.async {
            self.viewModel.isConnected = currentlyConnected
        }
    }
}
