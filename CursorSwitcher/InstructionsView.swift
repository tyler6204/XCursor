//
//  InstructionsView.swift
//  CursorSwitcher
//
//  Created by Tyler Yust on 1/29/25.
//

import SwiftUI

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Use XCursor")
                        .font(.title)
                        .bold()
                    
                    GroupBox("Setup Steps") {
                        VStack(alignment: .leading, spacing: 8) {
                            InstructionStep(number: 1, text: "Install required extensions in VSCode/Cursor:\n• Swift by Swift Server Work Group\n• Sweetpad by sweetpad\n• XCursor (Sync Xcode)")
                            InstructionStep(number: 2, text: "Download XCursor from TestFlight: testflight.apple.com/join/64N57Q66")
                            InstructionStep(number: 3, text: "Open your iOS project in Xcode")
                            InstructionStep(number: 4, text: "Press ⌥⌘T in Xcode to enable compact view")
                            InstructionStep(number: 5, text: "Open a file with SwiftUI preview and maximize the preview pane")
                            InstructionStep(number: 6, text: "In VSCode/Cursor, open the parent folder containing your .xcodeproj")
                            InstructionStep(number: 7, text: "Press ⌘⇧P, search for 'sweetpad' and select 'Generate Build Server Config'")
                            InstructionStep(number: 8, text: "Press ⌘⇧P again, run 'Build Without Run' and select any device")
                            InstructionStep(number: 9, text: "Position Xcode and VSCode/Cursor side by side")
                            InstructionStep(number: 10, text: "Resize Xcode to minimum width, keeping preview visible")
                            InstructionStep(number: 11, text: "Enable XCursor using the toggle in the menu bar")
                        }
                        .padding(.vertical, 8)
                    }
                    
                    GroupBox("Tips") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Files with SwiftUI previews will automatically open in Xcode")
                            Text("• The menu bar icon indicates the current status:")
                            VStack(alignment: .leading, spacing: 4) {
                                Label {
                                    Text("XCursor is disabled")
                                } icon: {
                                    Image(systemName: "text.page.slash")
                                }
                                Label {
                                    Text("Not connected to project")
                                } icon: {
                                    Image(systemName: "text.magnifyingglass")
                                }
                                Label {
                                    Text("Successfully connected")
                                } icon: {
                                    Image(systemName: "text.page")
                                }
                            }
                            .padding(.leading)
                            Text("• You can change the project folder at any time from the menu")
                        }
                        .padding(.vertical, 8)
                    }
                    
                    GroupBox("Troubleshooting") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• If connection is lost, try toggling the enable switch")
                            Text("• Ensure both Xcode and VSCode/Cursor are running")
                            Text("• Verify the correct project folder is selected")
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("Instructions")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Get Started") {
                        viewModel.completeFirstLaunch()
                        dismiss()
                        // Slight delay to allow smooth dismissal animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.showFolderSelector()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .bold()
                .foregroundColor(.secondary)
            Text(text)
        }
    }
}

#Preview {
    InstructionsView()
}
