//
//  EditorView.swift
//  Mark
//
//  Created by Mikhail Korzh on 07.09.2026.
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

struct EditorView: View {
    @Binding var document: Document
    @State private var isSpeakerSheetPresented = false
    
    private var parsedDocument: ParsedDocument {
        Parser().parse(document.text)
    }

    /// Creates the editor and connects it to the document text and parser.
    var body: some View {
        VStack {
            TextEditorView(text: $document.text,
                           caretPosition: $document.meta.caretPosition,
                           isLocked: $document.meta.isLocked
            )
            .focusedSceneValue(\.document, $document)
            .focusedSceneValue(\.speakerAction,
                                { isSpeakerSheetPresented = true }
            )
        }
        .sheet(isPresented: $isSpeakerSheetPresented) {
            SpeakerView(
                speakers: parsedDocument.speakers,
                speakerData: $document.meta.speakerData
            )
        }
    }
}

#Preview {
    EditorView(
        document: .constant(
            Document(
                text: "INTERVIEWER: Hello, world!"
            )
        )
    )
}
