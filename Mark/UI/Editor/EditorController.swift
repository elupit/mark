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
    private var lineSpacing = DefaultSettings.editorLineSpacing
    private var paragraphSpacing = DefaultSettings.editorParagraphSpacing
    private var highlightColor = DefaultSettings.editorHighlightColor
    private var textWidth = DefaultSettings.editorTextWidth
    private var justifyText = DefaultSettings.editorJustifyText
    private var interviewerBold = DefaultSettings.editorInterviewerBold
    private var automaticSymbolBalancing = DefaultSettings.editorAutomaticSymbolBalancing
    private var wrapSelection = DefaultSettings.editorWrapSelection
    
    private var isCompletingInput = false
    private var isUndoGroupOpen = false
    
    private var regularFont: NSFont { makeFont(weight: .regular) }
    private var boldFont: NSFont { makeFont(weight: .bold) }
    
    enum SymbolPairs {
        static let opening: [String: String] = [
            "(": ")",
            "[": "]",
            "{": "}",
            "<": ">"
        ]
        
        static let closing: Set<String> = Set(opening.values)
    }
    
    private var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = fontSize * lineSpacing.multiplier
        style.paragraphSpacing = fontSize * paragraphSpacing.multiplier
        style.alignment = justifyText ? .justified : .natural
        return style
    }
    
    // MARK: - Main
    
    init(
        document: MarkDocument,
        parsedDocumentStore: ParsedDocumentStore
    ) {
        self.document = document
        self.store = parsedDocumentStore
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let replacementString else { return true }
                
        if !isCompletingInput {
            if affectedCharRange.length > 0,
               wrapSelection,
               wrapSelection(in: textView, range: affectedCharRange, symbol: replacementString) {
                return false
            }
            
            if affectedCharRange.length == 0,
               automaticSymbolBalancing,
               balanceSymbol(in: textView, location: affectedCharRange.location, symbol: replacementString) {
                return false
            }
        }
        
        if !(textView.undoManager?.isUndoing ?? false),
           !(textView.undoManager?.isRedoing ?? false),
           !isUndoGroupOpen {
            textView.undoManager?.beginUndoGrouping()
            isUndoGroupOpen = true
        }
            
        setTextChange(oldRange: affectedCharRange, newLength: replacementString.utf16.count)
        
        return true
    }
    
    /// Updates the text and its parsed structure after an edit.
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        
        let isUndoing = textView.undoManager?.isUndoing ?? false
        let isRedoing = textView.undoManager?.isRedoing ?? false

        document.text = textView.string

        if let textChange {
            if !isUndoing && !isRedoing {
                let oldHighlights = document.meta.highlights
                updateHighlights(for: textChange)
                registerHighlightUndo(old: oldHighlights)
            }

            let result = store.update(document.text, on: textChange)

            applyIncrementalFormatting(in: result)
        } else {
            store.parse(document.text)
            reformatEntireDocument()
        }

        self.textChange = nil

        if isUndoGroupOpen,
           !isUndoing,
           !isRedoing {
            textView.undoManager?.endUndoGrouping()
            isUndoGroupOpen = false
        }
    }
    
    // MARK: - Configuration
    
    /// Configures the text view with the specified font and layout settings.
    ///
    /// This method sets up the internal state, assigns the text view's content from the document,
    /// parses the text, and triggers an initial layout and reformatting pass.
    func configure(
        _ textView: NSTextView,
        fontName: String,
        fontSize: Double,
        lineSpacing: LineSpacing,
        paragraphSpacing: ParagraphSpacing,
        highlightColor: HighlightColor,
        textWidth: Double,
        justifyText: Bool,
        interviewerBold: Bool,
        automaticSymbolBalancing: Bool,
        wrapSelection: Bool
    ) {
        self.textView = textView

        self.fontName = fontName
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
        self.highlightColor = highlightColor
        self.textWidth = textWidth
        self.interviewerBold = interviewerBold
        self.automaticSymbolBalancing = automaticSymbolBalancing
        self.wrapSelection = wrapSelection

        if let markTextView = textView as? MarkTextView {
            markTextView.textWidth = textWidth
            markTextView.editorController = self

            markTextView.onResize = { [weak self] in
                self?.updateTextWidth()
            }
        }

        textView.string = document.text

        store.parse(document.text)

        updateTextWidth()
        reformatEntireDocument()
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
    func updateSettingsIfNeeded(
        fontName: String,
        fontSize: Double,
        lineSpacing: LineSpacing,
        paragraphSpacing: ParagraphSpacing,
        highlightColor: HighlightColor,
        textWidth: Double,
        justifyText: Bool,
        interviewerBold: Bool,
        automaticSymbolBalancing: Bool,
        wrapSelection: Bool
    ) {
        let fontChanged = self.fontName != fontName || self.fontSize != fontSize
        let paragraphStyleChanged = self.lineSpacing != lineSpacing || self.paragraphSpacing != paragraphSpacing || self.justifyText != justifyText
        let widthChanged = self.textWidth != textWidth
        let interviewerStyleChanged = self.interviewerBold != interviewerBold
        let completeChanged = self.automaticSymbolBalancing != automaticSymbolBalancing || self.wrapSelection != wrapSelection
        let highlightChanged = self.highlightColor != highlightColor

        guard fontChanged
                || paragraphStyleChanged
                || widthChanged
                || interviewerStyleChanged
                || completeChanged
                || highlightChanged
        else { return }

        self.fontName = fontName
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
        self.highlightColor = highlightColor
        self.textWidth = textWidth
        self.justifyText = justifyText
        self.interviewerBold = interviewerBold
        self.automaticSymbolBalancing = automaticSymbolBalancing
        self.wrapSelection = wrapSelection

        if widthChanged {
            updateTextWidth()
        }

        if fontChanged || interviewerStyleChanged || paragraphStyleChanged || highlightChanged {
            reformatEntireDocument()
        }
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
    
    // MARK: - Actions
    
    /// Highlights the currently selected text in the text view.
    ///
    /// This method checks if there is a valid selection and, if so, adds a new highlight
    /// to the document's metadata and applies the highlight formatting to the text storage.
    func highlightSelection() {
        guard let textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else { return }
        
        let oldHighlights = document.meta.highlights
        var newRange = TextRange(location: selectedRange.location, length: selectedRange.length)
        
        var updatedHighlights: [Highlight] = []
        var handled = false
        
        for highlight in oldHighlights {
            let existingRange = highlight.range
            
            // Exact same range - remove highlight
            if existingRange == newRange {
                handled = true
                continue
            }
            
            // Within highlighted range (or on bounds) — split or trim
            if newRange.location >= existingRange.location && newRange.upperBound <= existingRange.upperBound {
                
                let leftLength = newRange.location - existingRange.location
                if leftLength > 0 {
                    let leftRange = TextRange(location: existingRange.location, length: leftLength)
                    updatedHighlights.append(Highlight(leftRange))
                }
                
                let rightLocation = newRange.upperBound
                let rightLength = existingRange.upperBound - rightLocation
                if rightLength > 0 {
                    let rightRange = TextRange(location: rightLocation, length: rightLength)
                    updatedHighlights.append(Highlight(rightRange))
                }
                
                handled = true
                continue
            }
            
            // Covers both highlighted and not — merge (or partial overlap)
            if newRange.intersects(existingRange) || newRange.isAdjacent(to: existingRange) {
                let minLocation = min(existingRange.location, newRange.location)
                let maxLocation = max(NSMaxRange(existingRange.nsRange), NSMaxRange(newRange.nsRange))
                let mergedRange = TextRange(location: minLocation, length: maxLocation - minLocation)
                
                // We will merge this into our newRange and continue checking against others
                newRange = mergedRange
                continue
            }
            
            // No overlap, keep existing highlight
            updatedHighlights.append(highlight)
        }
        
        // Not highlighted text (or merged result) — add highlight
        if !handled { updatedHighlights.append(Highlight(newRange)) }
        
        document.meta.highlights = updatedHighlights
        registerHighlightUndo(old: oldHighlights)
        applyHighlightFormatting(to: textStorage, range: selectedRange)
    }
}

// MARK: - Private

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
        
        textView.undoManager?.disableUndoRegistration()
        defer { textView.undoManager?.enableUndoRegistration() }
        
        textStorage.beginEditing()
        defer { textStorage.endEditing() }
        
        textStorage.removeAttribute(.font, range: range.nsRange)
        textStorage.addAttributes([.font: regularFont, .paragraphStyle: paragraphStyle], range: range.nsRange)
        
        applySpeakersFormatting(to: textStorage, for: store.document.segments)
        applyEscapeFormatting(to: textStorage, range: range.nsRange)
        applyHighlightFormatting(to: textStorage, range: range.nsRange)
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
        
        textView.undoManager?.disableUndoRegistration()
        defer { textView.undoManager?.enableUndoRegistration() }
        
        textStorage.beginEditing()
        defer { textStorage.endEditing() }
        
        textStorage.removeAttribute(.font, range: result.affectedRange.nsRange)
        textStorage.addAttributes([.font: regularFont, .paragraphStyle: paragraphStyle], range: result.affectedRange.nsRange)
        
        applySpeakersFormatting(to: textStorage, for: result.newSegments)
        if let range = result.newSegments.range {
            applyEscapeFormatting(to: textStorage, range: range.nsRange)
            applyHighlightFormatting(to: textStorage, range: range.nsRange)
        }
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
    
    /// Applies a background highlight to the ranges specified in the document's metadata.
    ///
    /// This method iterates through all highlights associated with the document and adds a
    /// `.backgroundColor` attribute to the text storage for each valid range.
    private func applyHighlightFormatting(to textStorage: NSTextStorage, range: NSRange) {
        removeHighlightFormatting(from: textStorage, range: range)
        
        for highlight in document.meta.highlights {
            let highlightRange = NSRange(
                location: highlight.range.location,
                length: highlight.range.length
            )

            guard NSMaxRange(highlightRange) <= textStorage.length else { continue }
            let intersection = NSIntersectionRange(range, highlightRange)
            guard intersection.length > 0 else { continue }

            textStorage.addAttribute(
                .markHighlight,
                value: true,
                range: intersection
            )

            textStorage.addAttribute(
                .backgroundColor,
                value: highlightColor.color,
                range: intersection
            )
        }
    }
    
    /// Updates the ranges of document highlights in response to a text change.
    ///
    /// This method iterates through the existing highlights and adjusts their ranges based on the
    /// old and new ranges of the text change. Highlights that are completely removed or fall
    /// within a deleted range are removed.
    private func updateHighlights(for change: TextChange) {
        let oldRange = change.oldRange
        let newRange = change.newRange
        let delta = newRange.length - oldRange.length

        for index in document.meta.highlights.indices.reversed() {
            let range = document.meta.highlights[index].range

            if oldRange.location >= range.upperBound { continue }
            if oldRange.upperBound <= range.location {
                document.meta.highlights[index].range = range.shifted(by: delta)
                continue
            }

            if oldRange.location <= range.location && oldRange.upperBound >= range.upperBound {
                if newRange.isEmpty { document.meta.highlights.remove(at: index) }
                else { document.meta.highlights[index].range = newRange }
                continue
            }

            if oldRange.location >= range.location &&
                oldRange.upperBound <= range.upperBound {
                document.meta.highlights[index].range = TextRange(location: range.location, length: range.length + delta)
                continue
            }

            let newEnd = range.upperBound + delta
            let newLength = newEnd - range.location

            if newLength > 0 {
                document.meta.highlights[index].range = TextRange(location: range.location, length: newLength)
            } else {
                document.meta.highlights.remove(at: index)
            }
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
    
    /// Records a text change by updating the `textChange` property with the old and new ranges.
    private func setTextChange(oldRange: NSRange, newLength: Int) {
        textChange = TextChange(
            oldRange: TextRange(location: oldRange.location, length: oldRange.length),
            newRange: TextRange(location: oldRange.location, length: newLength)
        )
    }
    
    /// Wraps the currently selected text in a specified symbol and its corresponding closing symbol.
    private func wrapSelection(in textView: NSTextView, range: NSRange, symbol: String) -> Bool {
        guard let closing = SymbolPairs.opening[symbol] else { return false }
        
        let selectedText = (textView.string as NSString).substring(with: range)
        let replacement = symbol + selectedText + closing
        
        textChange = TextChange(
            oldRange: TextRange(location: range.location, length: range.length),
            newRange: TextRange(location: range.location, length: replacement.utf16.count)
        )
        
        isCompletingInput = true
        textView.insertText(replacement, replacementRange: range)
        isCompletingInput = false
        
        textView.setSelectedRange(NSRange(location: range.location + replacement.utf16.count, length: 0))
        
        return true
    }
    
    /// Balances a typed symbol by either skipping over an existing closing symbol or inserting a matching closing symbol.
    private func balanceSymbol(in textView: NSTextView, location: Int, symbol: String) -> Bool {
        if SymbolPairs.closing.contains(symbol) {
            if location < textView.string.utf16.count {
                let next = (textView.string as NSString).substring(with: NSRange(location: location, length: 1))
                
                if next == symbol {
                    textView.setSelectedRange(NSRange(location: location + 1, length: 0))
                    return true
                }
            }
            
            return false
        }
        
        guard let closing = SymbolPairs.opening[symbol] else { return false }
        let replacement = symbol + closing
        
        textChange = TextChange(
            oldRange: TextRange(location: location, length: 0),
            newRange: TextRange(location: location, length: replacement.utf16.count)
        )
        
        isCompletingInput = true
        textView.insertText(replacement, replacementRange: NSRange(location: location, length: 0))
        isCompletingInput = false
        
        textView.setSelectedRange(NSRange(location: location + symbol.utf16.count, length: 0))
        
        return true
    }
    
    /// Removes highlight formatting from the specified range in the text storage.
    private func removeHighlightFormatting(from textStorage: NSTextStorage, range: NSRange) {
        textStorage.removeAttribute(.markHighlight, range: range)
        textStorage.removeAttribute(.backgroundColor, range: range)
    }
    
    /// Registers an undo action for highlight changes in the document.
    ///
    /// This method captures the current state of highlights and registers an undo operation
    /// that restores the old highlights, reformats the document, and recursively registers
    /// a redo action.
    private func registerHighlightUndo(old: [Highlight]) {
        guard let undoManager = textView?.undoManager else { return }

        let new = document.meta.highlights

        undoManager.registerUndo(withTarget: self) { controller in
            controller.document.meta.highlights = old

            if let textView = controller.textView,
               let textStorage = textView.textStorage {
                controller.applyHighlightFormatting(
                    to: textStorage,
                    range: NSRange(location: 0, length: textStorage.length)
                )
            }

            controller.registerHighlightUndo(old: new)
        }
    }
}
