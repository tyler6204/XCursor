//
//  CursorSwitcherApp.swift
//  XCursor
//
//  Created by Tyler Yust on 1/29/25.
//

import SwiftUI
import Cocoa
import AppKit
import ApplicationServices

@main
struct CursorSwitcherApp: App {
    @StateObject var model: ViewModel = ViewModel.shared
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some Scene {
        MenuBarExtra {
            AppMenu()
                .environmentObject(model)
            
        } label: {
            AppIcon()
                .environmentObject(model)
                .onAppear {
                    
                    if model.isFirstLaunch {
                        openWindow(id: "Instructions")
                    } else {
                        model.showFolderSelector()
                    }
                }
        }
    
        
        WindowGroup("Instructions", id: "Instructions") {
            InstructionsView()
                .environmentObject(model)
        }
        .windowStyle(.automatic)
        .windowResizability(.automatic)
    }
}
