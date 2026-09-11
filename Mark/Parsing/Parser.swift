//
//  Parser.swift
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

import Foundation

/// Parses interview transcript structure from plain text.
///
/// The text itself remains the source of truth. The parser only produces
/// structural information describing speaker segments and their ranges.
struct Parser {

    /// Parses the complete document.
    ///
    /// This is the canonical parsing operation and is also used as the
    /// correctness reference for incremental parsing.
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
               let marker = parseSpeakerMarker(
                    text: text,
                    scanner: &scanner
               ) {

                // Finish the previous segment before starting a new one.
                if let speaker = currentSpeaker,
                   let rangeStart = currentRangeStart,
                   let speakerRange = currentSpeakerRange,
                   let textStart = currentTextStart {
                    let textEnd = textEnd(in: text,from: textStart, to: marker.rangeStart)

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

            guard let character = scanner.advance() else {
                break
            }

            if isNewline(character) {
                isAtParagraphStart = true
            } else {
                isAtParagraphStart = false
            }
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
}

// MARK: - Speaker marker

private extension Parser {

    struct SpeakerMarker {
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
                colonPosition = lookahead.position
                break
            }

            if isNewline(character) {
                return nil
            }

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

    /// Appends a segment using absolute document positions.
    func appendSegment(to segments: inout [Segment], speaker: String, rangeStart: Int, speakerRange: TextRange, textStart: Int, end: Int, text: String) {
        let textEnd = textEnd(in: text, from: textStart, to: end)

        segments.append(
            Segment(
                speaker: speaker,
                range: TextRange(location: rangeStart, length: end - rangeStart),
                speakerRange: speakerRange,
                textRange: TextRange(location: textStart, length: textEnd - textStart)
            )
        )
    }
}

// MARK: - Character helpers

private extension Parser {

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
        let start = text.utf16.index(text.utf16.startIndex, offsetBy: range.location)
        let end = text.utf16.index(start, offsetBy: range.length)
        return String(text.utf16[start..<end]) ?? ""
    }
}
