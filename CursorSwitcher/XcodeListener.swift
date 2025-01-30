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
    let port: NWEndpoint.Port = 8124
    var listener: NWListener!
    private var projectRoot: URL?
    private var viewModel: ViewModel
    private var reconnectTimer: Timer?
    private let reconnectInterval: TimeInterval = 5.0 // Reconnect every 5 seconds
    private var hasActiveConnection = false

    init(projectRoot: URL, viewModel: ViewModel) {
        self.projectRoot = projectRoot
        self.viewModel = viewModel
        do {
            self.listener = try NWListener(using: .tcp, on: port)
            print("🚀 XcodeListener is listening on port \(port)")
        } catch { 
            fatalError("❌ Unable to create listener: \(error)")
        }
    }

    func start() {
        listener.stateUpdateHandler = { [weak self] newState in
            guard let self = self else { return }
            
            switch newState {
            case .ready:
                print("✅ XCursor is running on port \(self.port)")
                DispatchQueue.main.async {
                    if !self.hasActiveConnection {
                        self.viewModel.isConnected = false
                        self.startReconnectTimer()
                    }
                }
            case .failed, .cancelled:
                print("❌ XCursor connection failed or cancelled")
                DispatchQueue.main.async {
                    self.hasActiveConnection = false
                    self.viewModel.isConnected = false
                    self.startReconnectTimer()
                }
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            guard let self = self else { return }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    DispatchQueue.main.async {
                        self.hasActiveConnection = true
                        self.viewModel.isConnected = true
                        self.stopReconnectTimer()
                    }
                case .failed, .cancelled:
                    DispatchQueue.main.async {
                        self.hasActiveConnection = false
                        self.viewModel.isConnected = false
                        self.startReconnectTimer()
                    }
                default:
                    break
                }
            }
            
            connection.start(queue: .main)
            self.receive(on: connection)
        }

        listener.start(queue: .main)
    }

    private func startReconnectTimer() {
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.hasActiveConnection {
                print("🔄 Attempting to reconnect...")
                self.listener.cancel()
                do {
                    self.listener = try NWListener(using: .tcp, on: self.port)
                    self.start()
                } catch {
                    print("❌ Failed to create new listener: \(error)")
                }
            }
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
            if let data = data, let message = String(data: data, encoding: .utf8) {
                self.handleMessage(message)
            }
            
            if let error = error {
                print("❌ Connection error: \(error)")
                connection.cancel()
                return
            }
            
            if isComplete {
                connection.cancel()
            } else {
                self.receive(on: connection)
            }
        }
    }

    func updateProjectRoot(_ newRoot: URL) {
        self.projectRoot = newRoot
        print("📂 Updated project root to: \(newRoot.path)")
    }

    private func handleMessage(_ message: String) {
        print("Message Received")
        
        // Try parsing as JSON first
        if let data = message.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let filePath = dict["path"] {
            handleFilePath(filePath)
        } else {
            // Fallback to treating the message as a plain file path
            // Clean up the message by removing any trailing whitespace or newlines
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
        
        // Start a security-scoped resource access
        guard projectRoot.startAccessingSecurityScopedResource() else {
            print("❌ Failed to access security-scoped resource")
            return false
        }
        defer {
            projectRoot.stopAccessingSecurityScopedResource()
        }
        
        
        // Try to read the file contents directly without additional permission prompts
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

        // Locate Xcode on the system by its bundle identifier
        guard let xcodeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.dt.Xcode") else {
            print("❌ Xcode not found on the system.")
            return
        }

        let fileURL = URL(fileURLWithPath: path)

        // Open the file in Xcode without bringing it to the foreground
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false // Ensures Xcode does NOT become active

        NSWorkspace.shared.open([fileURL], withApplicationAt: xcodeURL, configuration: config, completionHandler: nil)
        
        print("✅ Successfully opened file in Xcode (in background): \(path)")
    }


}
