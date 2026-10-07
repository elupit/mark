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
    @AppStorage(DefaultKeys.Editor.lineSpacing) private var lineSpacingRaw = DefaultSettings.editorLineSpacing.rawValue
    @AppStorage(DefaultKeys.Editor.paragraphSpacing) private var paragraphSpacingRaw = DefaultSettings.editorParagraphSpacing.rawValue
    @AppStorage(DefaultKeys.Editor.textWidth) private var textWidth = DefaultSettings.editorTextWidth
    @AppStorage(DefaultKeys.Editor.justifyText) private var justifyText = DefaultSettings.editorJustifyText
    @AppStorage(DefaultKeys.Editor.interviewerBold) private var interviewerBold = DefaultSettings.editorInterviewerBold
    
    private var lineSpacing: LineSpacing { LineSpacing(rawValue: lineSpacingRaw) ?? .normal }
    private var paragraphSpacing: ParagraphSpacing { ParagraphSpacing(rawValue: paragraphSpacingRaw) ?? .normal }
    
    @State private var fontPicker = FontPicker()
    @State private var showFontWarning = false
    @State private var unsupportedFontName = ""

    var body: some View {
        Form {
            
            // MARK: - Typography
            
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
                
                // Line Spacing
                Picker("Line Spacing", selection: $lineSpacingRaw) {
                    ForEach(LineSpacing.allCases) { spacing in
                        Text(spacing.title).tag(spacing.rawValue)
                    }
                }
                
                // Paragraph Spacing
                Picker("Paragraph Spacing", selection: $paragraphSpacingRaw) {
                    ForEach(ParagraphSpacing.allCases) { spacing in
                        Text(spacing.title).tag(spacing.rawValue)
                    }
                }
                
                // Text Width
                Slider(value: $textWidth, in: 200...1400) {
                    Text("Text Width")
                } currentValueLabel: {
                    Text("\(textWidth)%")
                } ticks: {
                    SliderTick(200) { Text("Small") }
                    SliderTick(600) { Text("Default") }
                    SliderTick(1400) { Text("Large") }
                }
                
                // Justify Text
                Toggle("Justify Text", isOn: $justifyText)

            }
            
            // MARK: - Speaker Formatting
            
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

#Preview {
    EditorSettingsView()
}
