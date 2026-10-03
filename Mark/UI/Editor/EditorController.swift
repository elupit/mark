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
    
    // Formatting
    private var fontName = DefaultSettings.editorFontName
    private var fontSize = DefaultSettings.editorFontSize
    private var textWidth = DefaultSettings.editorTextWidth
    
    private var interviewerBold = DefaultSettings.editorInterviewerBold
    
    private var regularFont: NSFont { makeFont(weight: .regular) }
    private var boldFont: NSFont { makeFont(weight: .bold) }
    
    init(
        document: MarkDocument,
        parsedDocumentStore: ParsedDocumentStore
    ) {
        self.document = document
        self.store = parsedDocumentStore
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        let replacement = replacementString ?? ""
        let newRange = NSRange(location: affectedCharRange.location, length: replacement.utf16.count)
        
        textChange = TextChange(
            oldRange: TextRange(location: affectedCharRange.location, length: affectedCharRange.length),
            newRange: TextRange(location: newRange.location, length: newRange.length)
        )
        
        return true
    }
    
    /// Updates the text and its parsed structure after an edit.
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }

        document.text = textView.string

        if let textChange {
            let result = store.update(document.text, on: textChange)
            applyIncrementalFormatting(in: result)
        } else {
            store.parse(document.text)
            reformatEntireDocument()
        }

        self.textChange = nil
    }
    
    /// Updates the text view if the new text is different from the current text.
    func updateTextIfNeeded(_ text: String, in textView: NSTextView) {
        guard textView.string != text else { return }
        
        harvest( )

        textChange = nil
        textView.string = text
        store.parse(text)

        reformatEntireDocument()
    }
    
    /// Updates the font settings and reformats the document if the new values differ from the current ones.
    func updateSettingsIfNeeded(fontName: String, fontSize: Double, textWidth: Double, interviewerBold: Bool) {
        let fontChanged = self.fontName != fontName || self.fontSize != fontSize
        let widthChanged = self.textWidth != textWidth
        let interviewerStyleChanged = self.interviewerBold != interviewerBold

        guard fontChanged || widthChanged || interviewerStyleChanged else { return }

        self.fontName = fontName
        self.fontSize = fontSize
        self.textWidth = textWidth
        self.interviewerBold = interviewerBold

        if widthChanged { updateTextWidth() }
        if fontChanged || interviewerStyleChanged { reformatEntireDocument() }
    }
    
    /// Configures the text view with the specified font and layout settings.
    ///
    /// This method sets up the internal state, assigns the text view's content from the document,
    /// parses the text, and triggers an initial layout and reformatting pass.
    func configure(
        _ textView: NSTextView,
        fontName: String,
        fontSize: Double,
        textWidth: Double,
        interviewerBold: Bool
    ) {
        self.textView = textView

        self.fontName = fontName
        self.fontSize = fontSize
        self.textWidth = textWidth
        self.interviewerBold = interviewerBold

        if let markTextView = textView as? MarkTextView {
            markTextView.textWidth = textWidth

            markTextView.onResize = { [weak self] in
                self?.updateTextWidth()
            }
        }

        textView.string = document.text

        store.parse(document.text)

        updateTextWidth()
        reformatEntireDocument()
    }
    
    /// Updates text formatting for segments whose speaker roles have changed.
    /// Called after editing speaker metadata to avoid reformatting the whole document.
    func updateSpeakerFormatting(old: SpeakerDataStore, new: SpeakerDataStore) {
        guard let textStorage = textView?.textStorage else { return }
        let changedSpeakers = Set(old.speakers.keys)
            .union(new.speakers.keys)
            .filter { old.role(for: $0) != new.role(for: $0) }

        let segments = store.document.segments.filter {
            changedSpeakers.contains($0.speaker)
        }

        textStorage.beginEditing()
        defer { textStorage.endEditing() }

        for segment in segments {
            textStorage.addAttribute(.font, value: regularFont, range: segment.range.nsRange)
        }

        applySpeakersFormatting(to: textStorage, for: segments)
    }
}

// MARK: - Formatting

private extension EditorController {
    
    /// Resets and applies all formatting styles across the entire document.
    ///
    /// This method clears existing font attributes and reapplies both speaker and escape
    /// formatting to the full text within the current text view.
    func reformatEntireDocument() {
        guard let textView = self.textView,
              let textStorage = textView.textStorage
        else { return }

        let length = textStorage.length
        guard length > 0 else { return }

        let range = TextRange(location: 0, length: textStorage.length)
        guard range.length > 0 else { return }

        textStorage.beginEditing()
        defer { textStorage.endEditing() }

        textStorage.removeAttribute(.font, range: range.nsRange)
        textStorage.addAttribute(.font, value: regularFont, range: range.nsRange)

        applySpeakersFormatting(to: textStorage, for: store.document.segments)
        applyEscapeFormatting(to: textStorage, range: range.nsRange)
    }
    
    /// Updates the width of the text container to match the current text width,
    /// constrained by the available width of the text view.
    func updateTextWidth() {
        guard let textView,
              let textContainer = textView.textContainer,
              textView.bounds.width > 0
        else { return }
        
        let availableWidth = textView.bounds.width - textView.textContainerInset.width * 2
        let width = min(textWidth, availableWidth)
        
        textContainer.containerSize = NSSize(
            width: width,
            height: .greatestFiniteMagnitude
        )
        
        textContainer.widthTracksTextView = false
    }
    
    /// Updates formatting for only the segments that have changed.
    ///
    /// This method clears the font attributes for old segments and applies updated
    /// speaker and escape formatting to the new segments within the text storage.
    ///
    /// - Parameter result: A `ParseResult` object containing the old and new segments to process.
    func applyIncrementalFormatting(in result: ParseResult) {
        guard let textView = self.textView,
              let textStorage = textView.textStorage
        else { return }
        
        textStorage.beginEditing()
        defer { textStorage.endEditing() }
        
        textStorage.removeAttribute(.font, range: result.affectedRange.nsRange)
        textStorage.addAttribute(.font, value: regularFont, range: result.affectedRange.nsRange)

        applySpeakersFormatting(to: textStorage, for: result.newSegments)
        if let range = result.newSegments.range {
            applyEscapeFormatting(to: textStorage, range: range.nsRange)
        }
    }
    
    // Formatting helpers
    
    /// Applies escape formatting to the specified range within the text storage.
    ///
    /// This method scans the text for escaped colons (`\:`), which are represented
    /// by the character codes 92 (backslash) and 58 (colon). When found, it applies
    /// a tertiary label color to the backslash to visually distinguish it as an escape character.
    ///
    /// - Parameters:
    ///   - textStorage: The text storage object containing the text to be formatted.
    ///   - range: The range of text to scan and format.
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
    
    /// Applies speaker-specific formatting to a given text storage.
    ///
    /// This method iterates through the provided segments and applies bold or regular fonts
    /// depending on whether the speaker is an interviewer. It also bolds the speaker's name.
    ///
    /// - Parameters:
    ///   - textStorage: The `NSTextStorage` instance to format.
    ///   - segments: An array of `Segment` objects representing the parts of the text to format.
    ///   - range: An optional `TextRange` limiting the formatting to a specific portion of the text.
    ///            If `nil`, the entire text storage is formatted.
    func applySpeakersFormatting(to textStorage: NSTextStorage, for segments: [Segment], in range: TextRange? = nil) {
        let range = range ?? TextRange(location: 0, length: textStorage.length)
        
        for segment in segments {
            guard segment.range.intersects(range) else { continue }
            let font = document.meta.speakers.isInterviewer(segment.speaker) && interviewerBold ? boldFont : regularFont
            textStorage.addAttribute(.font, value: font, range: segment.range.nsRange)
            textStorage.addAttribute(.font, value: boldFont, range: segment.speakerRange.nsRange)
        }
    }

    /// Creates a font with the specified weight.
    /// - Parameter weight: The weight of the font to create.
    /// - Returns: The configured `NSFont` instance.
    private func makeFont(weight: NSFont.Weight) -> NSFont {
        if fontName == DefaultSettings.editorFontName {
            return NSFont.systemFont(ofSize: fontSize, weight: weight)
        }

        return NSFontManager.shared.font(
            withFamily: fontName,
            traits: weight == .bold ? .boldFontMask : [],
            weight: weight == .bold ? 9 : 5,
            size: fontSize
        ) ?? NSFont.systemFont(ofSize: fontSize, weight: weight)
    }
}
