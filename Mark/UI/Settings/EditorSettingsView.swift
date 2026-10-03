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

    @AppStorage(DefaultKeys.Editor.fontName)    private var fontName    = DefaultSettings.editorFontName
    @AppStorage(DefaultKeys.Editor.fontSize)    private var fontSize    = DefaultSettings.editorFontSize
    @AppStorage(DefaultKeys.Editor.textWidth)   private var textWidth   = DefaultSettings.editorTextWidth
    
    @AppStorage(DefaultKeys.Editor.interviewerBold) private var interviewerBold = DefaultSettings.editorInterviewerBold
    
    @State private var fontPicker = FontPicker()
    @State private var showFontWarning = false
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
                
                // Text Width
                HStack {
                    Text("Text Width")
                    Spacer()
                    HStack(spacing: 2) {
                        Text("\(Int(textWidth))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)

                        Text("pt")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                        .accessibilityLabel("\(Int(textWidth)) points")

                    Stepper("", value: $textWidth, in: 200...1500, step: 50)
                        .labelsHidden()
                }
            }
            
            Section("Formatting") {
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
