//
//  Parser.swift
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

import Foundation

/// Parses interview transcript structure from plain text.
nonisolated struct Parser {
    
    // MARK: - Initial parsing
    
    /// Parses the provided plain text into a structured document.
    ///
    /// This method scans the input text for speaker markers at the beginning of paragraphs
    /// and divides the text into segments associated with each speaker.
    ///
    /// - Parameter text: The plain text string to be parsed.
    /// - Returns: A `ParsedDocument` containing the array of parsed segments.
    func parse(_ text: String) -> ParsedDocument {
        var scanner = Scanner(text)
        var segments: [Segment] = []
        
        var currentSpeaker: String?
        var currentRangeStart: Int?
        var currentSpeakerRange: TextRange?
        var currentTextStart: Int?
        
        var isAtParagraphStart = true
        
        while !scanner.isAtEnd {
            // A speaker marker can only appear at the beginning of a paragraph.
            if isAtParagraphStart,
               let marker = parseSpeakerMarker(text: text, scanner: &scanner) {

                // Finish the previous segment before starting a new one.
                if let speaker = currentSpeaker,
                   let rangeStart = currentRangeStart,
                   let speakerRange = currentSpeakerRange,
                   let textStart = currentTextStart {
                    
                    let textEnd = textEnd(in: text, from: textStart, to: marker.rangeStart)
                    segments.append(
                        Segment(
                            speaker: speaker,
                            range: TextRange(location: rangeStart, length: marker.rangeStart - rangeStart),
                            speakerRange: speakerRange,
                            textRange: TextRange(location: textStart, length: textEnd - textStart)
                        )
                    )
                }

                currentSpeaker = marker.speaker
                currentRangeStart = marker.rangeStart
                currentSpeakerRange = marker.speakerRange
                currentTextStart = marker.textStart

                isAtParagraphStart = false
                continue
            }

            guard let character = scanner.advance() else { break }
            if isNewline(character) { isAtParagraphStart = true }
            else { isAtParagraphStart = false }
        }

        // Finish the final segment.
        if let speaker = currentSpeaker,
           let rangeStart = currentRangeStart,
           let speakerRange = currentSpeakerRange,
           let textStart = currentTextStart {
            let textEnd = textEnd(in: text,from: textStart, to: scanner.position)

            segments.append(
                Segment(
                    speaker: speaker,
                    range: TextRange(location: rangeStart, length: scanner.position - rangeStart),
                    speakerRange: speakerRange,
                    textRange: TextRange(location: textStart, length: textEnd - textStart)
                )
            )
        }

        return ParsedDocument(segments: segments)
    }
    
    // MARK: - Incremental parsing

    func update(_ text: String, in document: ParsedDocument, on change: TextChange) -> ParseResult {
        let documentLength = document.segments.last?.range.upperBound ?? 0

        // Reparse the whole document after replacing all text.
        if change.oldRange.location == 0 &&
           change.oldRange.length >= documentLength {

            let newDocument = parse(text)
            
            #if DEBUG
            ParserDebug.recordFull(
            text: text,
            segments: newDocument.segments
            )
            #endif

            return ParseResult(
                document: newDocument,
                oldSegments: document.segments,
                newSegments: newDocument.segments
            )
        }
    
        guard let firstIndex = affectedSegmentIndex(in: document, on: change)
        else {
            let newDocument = parse(text)
            
            #if DEBUG
            ParserDebug.recordFull(
            text: text,
            segments: newDocument.segments
            )
            #endif
                        
            return ParseResult(
                document: newDocument,
                oldSegments: document.segments,
                newSegments: newDocument.segments
            )
        }


        let lastIndex = lastAffectedSegmentIndex(
            in: document,
            on: change,
            firstIndex: firstIndex
        )

        // Include the previous segment when a boundary is removed.

        let startIndex = firstIndex > 0 ? firstIndex - 1 : firstIndex

        let updatedLastRange = updatedRange(
            document.segments[lastIndex].range,
            for: change
        )

        let affectedEnd = max(
            updatedLastRange.upperBound,
            change.newRange.upperBound
        )

        let newEnd = min(
            text.utf16.count,
            max(affectedEnd, paragraphEnd(in: text, from: affectedEnd))
        )

        let rangeStart = document.segments[startIndex].range.location

        let newRange = TextRange(
            location: rangeStart,
            length: newEnd - rangeStart
        )

        let localText = substring(text, range: newRange)
        let parsed = parse(localText)

        var segments = document.segments
        segments.removeSubrange(startIndex...lastIndex)

        let oldSegments = Array(
            document.segments[startIndex...lastIndex]
        )
        let newSegments = parsed.segments.map {
            shifted($0, by: newRange.location)
        }

        segments.insert(contentsOf: newSegments, at: startIndex)

        let firstShiftedIndex = startIndex + newSegments.count
        let delta = change.newRange.length - change.oldRange.length

        if delta != 0 {
            for i in firstShiftedIndex..<segments.count {
                segments[i] = shifted(
                    segments[i],
                    by: delta
                )
            }
        }
        
        #if DEBUG
        ParserDebug.recordIncremental(
            text: text,
            change: change,
            oldSegments: oldSegments,
            newSegments: newSegments
        )
        #endif

        return ParseResult(
            document: ParsedDocument(segments: segments),
            oldSegments: oldSegments,
            newSegments: newSegments
        )
    }
    
    /// Finds the segment containing the changed text or insertion point.
    private func affectedSegmentIndex(in document: ParsedDocument, on change: TextChange) -> Int? {
        if !change.oldRange.isEmpty {
            return document.segments.firstIndex {
                $0.range.intersects(change.oldRange)
            }
        }
        
        return document.segments.firstIndex {
            $0.range.contains(change.oldRange.location)
            || $0.range.upperBound == change.oldRange.location
        }
    }
    
    /// Finds the last segment that may be affected by a text change.
    private func lastAffectedSegmentIndex(in document: ParsedDocument, on change: TextChange, firstIndex: Int) -> Int {
        let oldEnd = change.oldRange.upperBound

        var lastIndex = document.segments.lastIndex {
            $0.range.location <= oldEnd
        } ?? firstIndex

        if lastIndex + 1 < document.segments.count,
           document.segments[lastIndex].range.upperBound == oldEnd {
            lastIndex += 1
        }

        return lastIndex
    }
    
    /// Adjusts an old range to its position in the new text.
    private func updatedRange(_ range: TextRange, for change: TextChange) -> TextRange {
        let delta = change.newRange.length - change.oldRange.length

        if range.upperBound <= change.oldRange.location {
            return range
        }

        if range.location >= change.oldRange.upperBound {
            return TextRange(location: range.location + delta, length: range.length)
        }

        return TextRange(location: range.location, length: max(0, range.length + delta))
    }
    
    /// Converts a locally parsed segment into an absolute document segment.
    private func shifted(_ segment: Segment, by offset: Int) -> Segment {
        Segment(
            speaker: segment.speaker,
            range: shifted(segment.range, by: offset),
            speakerRange: shifted(segment.speakerRange, by: offset),
            textRange: shifted(segment.textRange, by: offset)
        )
    }
    
    /// Shifts a UTF-16 range by a document offset.
    private func shifted(_ range: TextRange, by offset: Int) -> TextRange {
        TextRange(location: range.location + offset, length: range.length)
    }
}

// MARK: - Speaker marker

nonisolated private extension Parser {

    nonisolated struct SpeakerMarker {
        let speaker: String
        let rangeStart: Int
        let speakerRange: TextRange
        let textStart: Int
    }

    /// Tries to parse a speaker marker at the scanner's current paragraph position.
    ///
    /// A marker has the form `SPEAKER: text` and must begin at the
    /// beginning of a paragraph.
    func parseSpeakerMarker(text: String, scanner: inout Scanner) -> SpeakerMarker? {
        let markerStart = scanner.position

        guard let firstCharacter = scanner.peek(),
              !isHorizontalWhitespace(firstCharacter),
              !isNewline(firstCharacter) else {
            return nil
        }

        var lookahead = scanner
        var colonPosition: Int?

        while let character = lookahead.peek() {
            if character == 58 {
                guard lookahead.peek(offset: -1) != 92 else {
                    lookahead.advance()
                    continue
                }

                colonPosition = lookahead.position
                break
            }

            if isNewline(character) { return nil }
            lookahead.advance()
        }

        guard let colonPosition else { return nil }

        let speakerLength = colonPosition - markerStart
        guard speakerLength > 0 else { return nil }

        let speakerRange = TextRange(location: markerStart, length: speakerLength)
        let speaker = substring(text, range: speakerRange)

        while scanner.position <= colonPosition {
            scanner.advance()
        }

        while let character = scanner.peek(), isHorizontalWhitespace(character) {
            scanner.advance()
        }

        return SpeakerMarker(
            speaker: speaker,
            rangeStart: markerStart,
            speakerRange: speakerRange,
            textStart: scanner.position
        )
    }
}

// MARK: - Character helpers

nonisolated extension Parser {

    /// Returns true for LF and CR line breaks.
    func isNewline(_ character: UInt16) -> Bool {
        character == 10 || character == 13
    }

    /// Returns true for spaces and tabs.
    func isHorizontalWhitespace(_ character: UInt16) -> Bool {
        character == 32 || character == 9
    }

    /// Returns the end of spoken text without trailing line breaks.
    func textEnd(in text: String, from start: Int, to end: Int) -> Int {
        var result = end
        while result > start {
            let index = text.utf16.index(text.utf16.startIndex, offsetBy: result - 1)
            guard isNewline(text.utf16[index]) else { break }
            result -= 1
        }
        return result
    }

    /// Extracts a string from a UTF-16 range.
    func substring(_ text: String, range: TextRange) -> String {
        let utf16 = text.utf16

        guard range.location >= 0,
              range.length >= 0,
              range.location + range.length <= utf16.count
        else {
            return ""
        }

        let start = utf16.index(utf16.startIndex, offsetBy: range.location)
        let end = utf16.index(start, offsetBy: range.length)

        return String(decoding: utf16[start..<end], as: UTF16.self)
    }
    
    /// Returns the end of the paragraph containing the given UTF-16 position.
    private func paragraphEnd(in text: String, from position: Int) -> Int {
        let utf16 = text.utf16
        var end = position

        while end < utf16.count {
            let index = utf16.index(utf16.startIndex, offsetBy: end)

            if isNewline(utf16[index]) {
                break
            }

            end += 1
        }

        return end
    }
}

/// Represents a change in text, defined by its old and new ranges.
nonisolated struct TextChange: Sendable, Equatable {
    let oldRange: TextRange
    let newRange: TextRange
}

nonisolated struct ParseResult: Sendable {
    let document: ParsedDocument
    let oldSegments: [Segment]
    let newSegments: [Segment]
}
