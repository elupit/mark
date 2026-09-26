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

struct DocumentView: View {

    @Bindable var document: MarkDocument

    @Environment(\.undoManager) private var undoManager

    @State private var parsedDocumentStore = ParsedDocumentStore()
    @State private var UIState = DocumentUIState()
    @State private var editorState = EditorState()

    var body: some View {

        TextEditorView(
            document: document,
            store: parsedDocumentStore,
            editorState: editorState
        )
        .focusedSceneValue(\.documentUIState, UIState)
        .onAppear {
            UIState.isLocked = document.meta.isLocked

            UIState.toggleLock = {
                changeLock(
                    from: document.meta.isLocked,
                    to: !document.meta.isLocked
                )
            }
        }
        .sheet(isPresented: $UIState.isSpeakerSheetPresented) {
            SpeakerSheet(
                speakers: parsedDocumentStore.speakers,
                speakerData: document.meta.speakers
            ) { newSpeakerData in
                let oldSpeakerData = document.meta.speakers
                guard oldSpeakerData != newSpeakerData else { return }
                changeSpeakerData(from: oldSpeakerData, to: newSpeakerData)
            }
            .frame(width: 500, height: 400)
        }
    }
    
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
