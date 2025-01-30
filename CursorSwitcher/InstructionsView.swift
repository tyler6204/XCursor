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
                            InstructionStep(number: 1, text: "Open your iOS project in both Xcode and VSCode/Cursor")
                            InstructionStep(number: 2, text: "In Xcode, open a file with SwiftUI preview and maximize the preview pane")
                            InstructionStep(number: 3, text: "Press ⌥⌘T in Xcode to enable compact view")
                            InstructionStep(number: 4, text: "Position Xcode and VSCode/Cursor side by side")
                            InstructionStep(number: 5, text: "Resize Xcode to as small as possible width wise, close the sidebar and make preview as large as possible")
                            InstructionStep(number: 6, text: "Enable XCursor using the toggle in the menu bar")
                            InstructionStep(number: 7, text: "Select your project root folder when prompted")
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
