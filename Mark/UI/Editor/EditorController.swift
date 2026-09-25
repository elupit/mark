//
//  EditorController.swift
//  Mark
//
//  Created by Mikhail Korzh on 23.09.2026.
//  Copyright © 2026 Mikhail Korzh.
//
//  Originally drafted with AI assistance;
//  heavily refactored and reviewed by a human.
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

final class EditorController: NSObject, NSTextViewDelegate {
    
    let document: MarkDocument
    let store: ParsedDocumentStore

    weak var textView: NSTextView?
    
    private var textChange: TextChange?
    private var editedParagraphRange = NSRange(location: 0, length: 0)
    
    private let regularFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    private let boldFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .bold)
    
    init(
        document: MarkDocument,
        parsedDocumentStore: ParsedDocumentStore
    ) {
        self.document = document
        self.store = parsedDocumentStore
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        let oldText = textView.string as NSString
        let oldParagraphRange = oldText.paragraphRange(for: affectedCharRange)

        let replacement = replacementString ?? ""
        let newText = oldText.replacingCharacters(in: affectedCharRange, with: replacement) as NSString
        let newRange = NSRange(location: affectedCharRange.location, length: replacement.utf16.count)
        
        textChange = TextChange(
            oldRange: TextRange(location: affectedCharRange.location, length: affectedCharRange.length),
            newRange: TextRange(location: newRange.location, length: newRange.length)
        )

        let newParagraphRange = newText.paragraphRange(for: newRange)
        editedParagraphRange = NSUnionRange(oldParagraphRange, newParagraphRange)

        return true
    }
    
    /// Updates the text and its parsed structure after an edit.
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        
        document.text = textView.string
        
        if let textChange {
            store.update(document.text, on: textChange)
        } else {
            store.parse(document.text)
        }
        
        applyFormatting(to: textView, paragraphRange: editedParagraphRange)
        textChange = nil
    }
    
    /// Updates the text view if the new text is different from the current text.
    func updateTextIfNeeded(_ text: String, in textView: NSTextView) {
        guard textView.string != text else { return }

        textChange = nil
        textView.string = text
        store.parse(text)

        applyFormatting(
            to: textView,
            paragraphRange: NSRange(location: 0, length: textView.string.utf16.count)
        )
    }
    
    /// Configures the text view with the initial text and applies formatting.
    /// - Parameter textView: The text view to configure.
    func configure(_ textView: NSTextView) {
        self.textView = textView
        
        textView.string = document.text
        store.parse(document.text)
        
        applyFormatting(to: textView, paragraphRange: NSRange(location: 0, length: textView.string.utf16.count))
    }
    
    /// Updates text formatting for segments whose speaker roles have changed.
    /// Called after editing speaker metadata to avoid reformatting the whole document.
    func updateSpeakerFormatting(old: SpeakerDataStore, new: SpeakerDataStore) {
        guard let textView else { return }

        let changedSpeakers = Set(old.speakers.keys)
        .union(new.speakers.keys)
        .filter {
            old.role(for: $0) != new.role(for: $0)
        }

        guard !changedSpeakers.isEmpty else {
            return
        }

        let affectedSegments = store.document.segments.filter {
            changedSpeakers.contains($0.speaker)
        }

        guard !affectedSegments.isEmpty else { return }

        for segment in affectedSegments {
            applyFormatting(to: textView, paragraphRange: segment.range.nsRange)
        }
    }
}

// MARK: - Formatting

private extension EditorController {

    func applyFormatting(to textView: NSTextView, paragraphRange: NSRange) {
        guard let textStorage = textView.textStorage else { return }

        let length = textStorage.length
        guard length > 0 else { return }

        let location = min(max(paragraphRange.location, 0), length)
        let safeRange = NSRange(
            location: location,
            length: min(max(paragraphRange.length, 0), length - location)
        )

        guard safeRange.length > 0 else { return }

        let range = TextRange(
            location: safeRange.location,
            length: safeRange.length
        )

        textStorage.beginEditing()
        defer { textStorage.endEditing() }

        textStorage.removeAttribute(.font, range: safeRange)
        textStorage.addAttribute(.font, value: regularFont, range: safeRange)

        for segment in store.document.segments {
            guard segment.range.intersects(range) else { continue }

            textStorage.addAttribute(
                .font,
                value: boldFont,
                range: segment.speakerRange.nsRange
            )
            
            if document.meta.speakers.isInterviewer(segment.speaker) {
                textStorage.addAttribute(
                    .font,
                    value: boldFont,
                    range: segment.range.nsRange
                )
            }
        }
        
        applyEscapeFormatting(to: textStorage, range: safeRange)
    }
    
    /// Applies font styling to a single transcript segment.
    /// Interviewer segments use bold text, while speaker markers are always bold.
    func applyFormatting(to textView: NSTextView, segment: Segment) {
        guard let textStorage = textView.textStorage else { return }
        let range = segment.range.nsRange
        guard NSMaxRange(range) <= textStorage.length else { return }

        textStorage.beginEditing()
        defer { textStorage.endEditing() }
        textStorage.removeAttribute(.font, range: range)

        let font = document.meta.speakers.isInterviewer(segment.speaker) ? boldFont : regularFont

        textStorage.addAttribute(
            .font,
            value: font,
            range: range
        )

        // Speaker marker always bold
        textStorage.addAttribute(
            .font,
            value: boldFont,
            range: segment.speakerRange.nsRange
        )
    }
    
    func applyEscapeFormatting(to textStorage: NSTextStorage, range: NSRange) {
        let text = textStorage.string as NSString
        let end = range.location + range.length - 1

        guard end > range.location else { return }

        for index in range.location..<end {
            if text.character(at: index) == 92,
               text.character(at: index + 1) == 58 {

                textStorage.addAttribute(
                    .foregroundColor,
                    value: NSColor.tertiaryLabelColor,
                    range: NSRange(location: index, length: 1)
                )
            }
        }
    }
}
