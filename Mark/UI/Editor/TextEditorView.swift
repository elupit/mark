//
//  TextEditorView.swift
//  Mark
//
//  Created by Mikhail Korzh on 09.09.2026.
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

struct TextEditorView: NSViewRepresentable {

    @Binding var text: String
    @Binding var caretPosition: Int?
    @Binding var isLocked: Bool
    @Binding var parsedDocumentStore: ParsedDocumentStore
    @Binding var speakerData: SpeakerDataStore

    let editorController: EditorController
    let presentation = Presentation()
    let textInsets = NSSize(width: 20, height: 40)

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            caretPosition: $caretPosition,
            isLocked: $isLocked,
            parsedDocumentStore: $parsedDocumentStore,
            speakerData: $speakerData,
            presentation: presentation
        )
    }

    func makeNSView(context: Context) -> NSScrollView {

        let scrollView = NSScrollView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        let savedCaretPosition = caretPosition

        textView.isEditable = !isLocked
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.textContainerInset = textInsets

        textView.font = .monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        )

        textView.string = text

        presentation.apply(
            parsedDocumentStore.parsedDocument,
            to: textView,
            paragraphRange: NSRange(location: 0, length: textView.string.utf16.count),
            speakerData: speakerData
        )

        textView.minSize = NSSize(width: 0, height: 0)

        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.delegate = context.coordinator
        scrollView.documentView = textView
        editorController.textView = textView

        if let savedCaretPosition {

            let position = min(
                max(savedCaretPosition, 0),
                textView.string.utf16.count
            )

            DispatchQueue.main.async {

                guard let window = textView.window else {
                    return
                }

                window.makeFirstResponder(textView)

                textView.setSelectedRange(
                    NSRange(location: position, length: 0)
                )
                
                textView.scrollRangeToVisible(
                    NSRange(location: position, length: 0)
                )
            }
        }

        return scrollView
    }

    func updateNSView(
        _ scrollView: NSScrollView,
        context: Context
    ) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        textView.isEditable = !isLocked
    }

    final class Coordinator: NSObject, NSTextViewDelegate {

        @Binding var text: String
        @Binding var caretPosition: Int?
        @Binding var isLocked: Bool
        @Binding var parsedDocumentStore: ParsedDocumentStore
        @Binding var speakerData: SpeakerDataStore

        let presentation: Presentation

        private var editedParagraphRange = NSRange(
            location: 0,
            length: 0
        )
        
        private var textChange: TextChange?

        init(
            text: Binding<String>,
            caretPosition: Binding<Int?>,
            isLocked: Binding<Bool>,
            parsedDocumentStore: Binding<ParsedDocumentStore>,
            speakerData: Binding<SpeakerDataStore>,
            presentation: Presentation
        ) {
            self._text = text
            self._caretPosition = caretPosition
            self._isLocked = isLocked
            self._parsedDocumentStore = parsedDocumentStore
            self._speakerData = speakerData
            self.presentation = presentation
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {

            let oldText = textView.string as NSString

            let oldParagraphRange = oldText.paragraphRange(
                for: affectedCharRange
            )

            let replacement = replacementString ?? ""

            let newText = oldText.replacingCharacters(
                in: affectedCharRange,
                with: replacement
            ) as NSString

            let newRange = NSRange(
                location: affectedCharRange.location,
                length: replacement.utf16.count
            )
            
            textChange = TextChange(
                oldRange: TextRange(
                    location: affectedCharRange.location,
                    length: affectedCharRange.length
                ),
                newRange: TextRange(
                    location: newRange.location,
                    length: newRange.length
                )
            )

            let newParagraphRange = newText.paragraphRange(
                for: newRange
            )

            editedParagraphRange = NSUnionRange(
                oldParagraphRange,
                newParagraphRange
            )

            return true
        }

        /// Updates the text and its parsed structure after an edit.
        func textDidChange(
            _ notification: Notification
        ) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            
            let newText = textView.string
            text = newText
            
            if let textChange {
                parsedDocumentStore.update(text: newText, change: textChange)
            }
            
            presentation.apply(
                parsedDocumentStore.parsedDocument,
                to: textView,
                paragraphRange: editedParagraphRange,
                speakerData: speakerData
            )
            
            textChange = nil
        }

        func textViewDidChangeSelection(
            _ notification: Notification
        ) {

            guard let textView = notification.object as? NSTextView else {
                return
            }

            caretPosition = textView.selectedRange().location
        }
    }
}
