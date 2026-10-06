//
//  EditorSettingsView.swift
//  Mark
//
//  Created by Mikhail Korzh on 22.09.2026.
//  Copyright © 2026 Mikhail Korzh.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import SwiftUI
import AppKit

struct EditorSettingsView: View {

    @AppStorage(DefaultKeys.Editor.fontName) private var fontName = DefaultSettings.editorFontName
    @AppStorage(DefaultKeys.Editor.fontSize) private var fontSize = DefaultSettings.editorFontSize
    @AppStorage(DefaultKeys.Editor.justifyText) private var justifyText = DefaultSettings.editorJustifyText
    
    @AppStorage(DefaultKeys.Editor.interviewerBold) private var interviewerBold = DefaultSettings.editorInterviewerBold
    
    @State private var fontPicker = FontPicker()
    @State private var showFontWarning = false
    @State private var showCustomizeLayout = false
    @State private var unsupportedFontName = ""

    var body: some View {
        Form {
            Section("Typography") {
                // Font
                HStack {
                    Text("Font")
                    Spacer()
                    Button(fontName) { showFontPanel() }
                        .accessibilityLabel("Font Name")
                    HStack(spacing: 2) {
                        Text("\(Int(fontSize))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .trailing)
                        
                        Text("pt")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .accessibilityLabel("\(Int(fontSize)) points")
                    Stepper("Font Size", value: $fontSize, in: 10...28, step: 1 )
                        .labelsHidden()
                }
                
                Toggle("Justify Text", isOn: $justifyText)
                
                HStack {
                    Text("Customize Layout")
                    Spacer()
                    Button("Customize…") { showCustomizeLayout = true }
                }
            }
            
            Section("Speaker Formatting") {
                // Interviewer text
                Toggle("Bold Interviewer Text", isOn: $interviewerBold)
            }
        }
        .formStyle(.grouped)
        
        .alert("Font Not Supported", isPresented: $showFontWarning) {
            Button("OK") {}
        } message: {
            Text("\(unsupportedFontName) does not provide both regular and bold styles. " +
                 "Mark requires both styles for speaker formatting.")
        }
        
        .sheet(isPresented: $showCustomizeLayout) {
            CustomizeLayoutView()
        }
    }
    
    private func showFontPanel() {
        fontPicker.onSelect = { name in
            fontName = name
            showFontWarning = false
            unsupportedFontName = ""
        }

        fontPicker.onUnsupportedFont = { name in
            showFontWarning = false

            DispatchQueue.main.async {
                unsupportedFontName = name
                showFontWarning = true
            }
        }

        fontPicker.show(currentFontName: fontName, size: fontSize)
    }
}

struct CustomizeLayoutView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(DefaultKeys.Editor.lineSpacing) private var lineSpacing = DefaultSettings.editorLineSpacing
    @AppStorage(DefaultKeys.Editor.paragraphSpacing) private var paragraphSpacing = DefaultSettings.editorParagraphSpacing
    @AppStorage(DefaultKeys.Editor.textWidth) private var textWidth = DefaultSettings.editorTextWidth

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Customize Layout") {
                    HStack {
                        Text("Line Spacing")
                        Spacer()
                        Slider(
                            value: $lineSpacing,
                            in: 0.8...2.0,
                            step: 0.1,
                            label: { Text("Line Spacing") }
                        )
                        .labelsHidden()
                        .frame(width: 200)
                        Text(lineSpacing.formatted(.number.precision(.fractionLength(2))))
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    
                    HStack {
                        Text("Paragraph Spacing")
                        Spacer()
                        Slider(
                            value: $paragraphSpacing,
                            in: 0...3,
                            step: 0.25,
                            label: { Text("Paragraph Spacing") }
                        )
                        .labelsHidden()
                        .frame(width: 200)
                        Text(paragraphSpacing.formatted(.number.precision(.fractionLength(2))))
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    
                    HStack {
                        Text("Text Column Width")
                        Spacer()
                        Slider(
                            value: $textWidth,
                            in: 300...1500,
                            step: 100,
                            label: { Text("Text Column Width") }
                        )
                        .labelsHidden()
                        .frame(width: 200)
                        Text(textWidth.formatted())
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .formStyle(.grouped)
        }
        Divider()

        HStack {
            Spacer()
            Button("Done") { dismiss() }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }
}

#Preview {
    EditorSettingsView()
}

#Preview {
    CustomizeLayoutView()
}
