//
//  AppState.swift
//  CursorSwitcher
//
//  Created by Tyler Yust on 1/29/25.
//

import Foundation
import AppKit
import ApplicationServices
import SwiftUI


class ViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isEnabled = UserDefaults.standard.bool(forKey: "IsEnabled")
    @Published var isFirstLaunch = !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")

    private var server: XcodeFileListener?
    
    static let shared = ViewModel()
    
    
    func completeFirstLaunch() {
        UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        isFirstLaunch = false
    }
    
    func showFolderSelector() {
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.message = "Select Your Project Root Folder"
            openPanel.prompt = "Select Project"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.center()
            
            // Make the panel stay on top
            openPanel.level = .modalPanel
            openPanel.makeKeyAndOrderFront(nil)
            openPanel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            
            openPanel.begin { response in
                if response == .OK {
                    if let url = openPanel.url {
                        self.storeFolderAccessPermission(url: url)
                        DispatchQueue.global(qos: .background).async {
                            self.startServer(with: url)
                        }
                    }
                }
            }
        }
    }
    
    func toggleEnabled() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: "IsEnabled")
        
        // Handle server state based on enabled status
        if isEnabled {
            // If we have a stored project root, restart the server
            if let bookmarkData = UserDefaults.standard.data(forKey: "ProjectRootBookmark") {
                do {
                    var isStale = false
                    let url = try URL(resolvingBookmarkData: bookmarkData,
                                    options: .withSecurityScope,
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale)
                    
                    if !isStale {
                        self.startServer(with: url)
                    }
                } catch {
                    print("❌ Failed to resolve bookmark: \(error)")
                }
            }
        } else {
            // Stop the server when disabled
            self.stopServer()
        }
    }
    
    func startServer(with url: URL) {
        DispatchQueue.main.async {
            self.server = XcodeFileListener(projectRoot: url, viewModel: self)
            self.server?.start()
            self.isConnected = true
        }
    }
    
    func stopServer() {
        DispatchQueue.main.async {
            self.server?.listener.cancel()
            self.server = nil
            self.isConnected = false
        }
    }
    
    func restartServer(with url: URL) {
        DispatchQueue.main.async {
            if let existingServer = self.server {
                existingServer.updateProjectRoot(url)
                print("✅ Updated existing server with new project root")
            } else {
                self.stopServer()
                self.startServer(with: url)
                print("✅ Started new server with project root")
            }
            self.isConnected = true
        }
    }
    
    func storeFolderAccessPermission(url: URL?) {
        guard let url = url else { return }

        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: "ProjectRootBookmark")
        } catch {
            print("❌ Failed to store project root bookmark: \(error)")
        }
    }

}
