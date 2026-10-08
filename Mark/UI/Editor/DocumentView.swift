//
//  DocumentView.swift
//  Mark
//
//  Created by Mikhail Korzh on 20.09.2026.
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
import UniformTypeIdentifiers

struct DocumentView: View {
    
    @Bindable var document: MarkDocument
    @Environment(\.undoManager) private var undoManager
    
    @AppStorage(DefaultKeys.Editor.fontName) private var fontName = DefaultSettings.editorFontName
    @AppStorage(DefaultKeys.Editor.fontSize) private var fontSize = DefaultSettings.editorFontSize
    @AppStorage(DefaultKeys.Editor.lineSpacing) private var lineSpacing = DefaultSettings.editorLineSpacing
    @AppStorage(DefaultKeys.Editor.paragraphSpacing) private var paragraphSpacing = DefaultSettings.editorParagraphSpacing
    @AppStorage(DefaultKeys.Editor.textWidth) private var textWidth = DefaultSettings.editorTextWidth
    @AppStorage(DefaultKeys.Editor.justifyText) private var justifyText = DefaultSettings.editorJustifyText
    
    @AppStorage(DefaultKeys.Editor.interviewerBold) private var interviewerBold = DefaultSettings.editorInterviewerBold
    
    @AppStorage(DefaultKeys.Editor.automaticSymbolBalancing) private var automaticSymbolBalancing = DefaultSettings.editorAutomaticSymbolBalancing
    @AppStorage(DefaultKeys.Editor.wrapSelection) private var wrapSelection = DefaultSettings.editorWrapSelection
    
    @State private var store = ParsedDocumentStore()
    @State private var UIState = DocumentUIState()
    @State private var editorState = EditorState()
    
    @State private var isExporting = false
    
    var body: some View {
        
        TextEditorView(
            document: document,
            store: store,
            editorState: editorState,
            fontName: fontName,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            paragraphSpacing: paragraphSpacing,
            textWidth: textWidth,
            justifyText: justifyText,
            interviewerBold: interviewerBold,
            automaticSymbolBalancing: automaticSymbolBalancing,
            wrapSelection: wrapSelection
        )
        
        // Document UI State
        .focusedSceneValue(\.documentUIState, UIState)
        .onAppear {
            UIState.isLocked = document.meta.isLocked
            UIState.toggleLock = { changeLock( from: document.meta.isLocked, to: !document.meta.isLocked ) }
            UIState.export = { isExporting = true }
        }
        
        // Sheet
        .sheet(isPresented: $UIState.isSpeakerSheetPresented) {
            SpeakerSheet( speakers: store.speakers, speakerData: document.meta.speakers ) { newSpeakerData in
                let oldSpeakerData = document.meta.speakers
                guard oldSpeakerData != newSpeakerData else { return }
                changeSpeakerData(from: oldSpeakerData, to: newSpeakerData)
            }
            .frame(width: 500, height: 400)
        }
        
        // Export
        .fileExporter(
            isPresented: $isExporting,
            document: MarkTextExport(text: document.text),
            contentType: .plainText,
            defaultFilename: "Untitled"
        ) { _ in }
    }
}

    // MARK: - Helpers

extension DocumentView {
    
    func changeSpeakerData(from old: SpeakerDataStore, to new: SpeakerDataStore) {
        document.meta.speakers = new
        editorState.controller?.updateSpeakerFormatting(old: old, new: new)

        undoManager?.registerUndo(withTarget: document) { document in
            self.changeSpeakerData(from: new, to: old)
        }

        undoManager?.setActionName("Change Speaker Roles")
    }
    
    func changeLock(from old: Bool, to new: Bool) {
        document.meta.isLocked = new
        UIState.isLocked = new

        undoManager?.registerUndo(withTarget: document) { document in
            self.changeLock(from: new, to: old)
        }

        undoManager?.setActionName(
            new ? "Lock Document" : "Unlock Document"
        )
    }
}

#Preview {
    DocumentView(document: MarkDocument())
}
