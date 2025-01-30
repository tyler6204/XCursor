//
//  AppMenu.swift
//  XCursor
//
//  Created by Tyler Yust on 1/29/25.
//

import SwiftUI

struct AppMenu: View {
    @EnvironmentObject var appState: ViewModel
    @Environment(\.openWindow) private var openWindow

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Enable Cursor-Switch", isOn: $appState.isEnabled)
                .onChange(of: appState.isEnabled) {
                    appState.toggleEnabled()
                }
                .padding(.horizontal, 8)
            
            Text("Status: \(statusText)")
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            
            Divider()
            
            Button(action: {
                if let newURL = requestProjectRootAccess() {
                    appState.restartServer(with: newURL)
                }
            }) {
                Text("Change Project Folder...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            
            Divider()
            
            Button(action: {
                openWindow(id: "Instructions")
                NSApp.activate(ignoringOtherApps: true)
            }) {
                Text("How to Use...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        if !appState.isEnabled {
            return .gray
        } else if !appState.isConnected {
            return .red
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        if !appState.isEnabled {
            return "Disabled"
        } else if !appState.isConnected {
            return "Not Connected"
        } else {
            return "Connected"
        }
    }
    
    private func requestProjectRootAccess() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.message = "Please select your project root folder"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        // Make the panel stay on top
        openPanel.level = .modalPanel
        openPanel.makeKeyAndOrderFront(nil)
        openPanel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        if openPanel.runModal() == .OK {
            let selectedFolder = openPanel.url
            appState.storeFolderAccessPermission(url: selectedFolder)
            return selectedFolder
        }
        return nil
    }
}

struct AppIcon: View {
    @EnvironmentObject var appState: ViewModel
    
    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.hierarchical)
            .foregroundColor(statusColor)
    }
    
    private var iconName: String {
        if !appState.isEnabled {
            return "text.page.slash"
        } else if !appState.isConnected {
            return "text.magnifyingglass"
        } else {
            return "text.page"
        }
    }
    
    private var statusColor: Color {
        if !appState.isEnabled {
            return .gray
        } else if !appState.isConnected {
            return .red
        } else {
            return .green
        }
    }
}

#Preview {
    AppMenu()
        .environmentObject(ViewModel())
}
