//
//  Parser.swift
//  Mark
//
//  Created by Mikhail Korzh on 26.09.2026.
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
//  ---
//
//  Inspired by Beat
//  Copyright © Kaikki on haurasta Oy & Lauri-Matti Parppei 2019-2026.
//
//  ---
//
//  This small file contains hours I spent trying to systematize
//  the code and account for the various parsing scenarios. The
//  first version of the Parser, largely developed with the help
//  of AI, simply did not work, and this implementation was born
//  out of that failure. Although it is not particularly clean yet,
//  as far as I can tell, it works better for now.
//
//  Attempts to systematize the code also turned into attempts
//  to systematize my own thoughts, which came to me amid the
//  twists and turns of life. So working on this file has brought
//  not only frustrating bugs, but also a certain therapeutic
//  effect.
//
//  — Mikhail Korzh, 02.10.2026
//

import Foundation

nonisolated struct Parser {
    
    // MARK: - Initial parsing
    
    func parse(_ text: String) -> ParsedDocument {
        var scanner = Scanner(text)
        var segments: [Segment] = []
        var currentSpeaker: SpeakerLabel?
        
        // We start from the beginning
        var isLineStart = true
        
        // Go through the text until the end.
        while !scanner.isAtEnd {
            if isLineStart,
               let next = parseSpeaker(text, scanner: &scanner) {
                
                // Finish the previous segment before starting a new one.
                if let previous = currentSpeaker {
                    let textEnd = textEnd(
                        in: text,
                        from: previous.textStart,
                        to: next.rangeStart
                    )
                    
                    let segment = Segment(
                        speaker: previous.speaker,
                        range: TextRange(
                            location: previous.rangeStart,
                            length: next.rangeStart - previous.rangeStart
                        ),
                        speakerRange: previous.speakerRange,
                        textRange: TextRange(
                            location: previous.textStart,
                            length: textEnd - previous.textStart
                        )
                    )
                    
                    segments.append(
                        segment
                    )
                }
                
                currentSpeaker = next
                isLineStart = false
                
                continue
            }
            
            //  If no speaker is found (or it's not the start of a line), scanner.advance() moves to the next character.
            guard let character = scanner.advance() else { break }
            
            if character.isNewline { isLineStart = true }
            else { isLineStart = false}
        }
        
        // Append the final segment.
        if let speaker = currentSpeaker {
            let textEnd = textEnd(
                in: text,
                from: speaker.textStart,
                to: scanner.position
            )
            
            segments.append(
                Segment(
                    speaker: speaker.speaker,
                    range: TextRange(
                        location: speaker.rangeStart,
                        length: scanner.position - speaker.rangeStart
                    ),
                    speakerRange: speaker.speakerRange,
                    textRange: TextRange(
                        location: speaker.textStart,
                        length: textEnd - speaker.textStart
                    )
                )
            )
        }
        
        return ParsedDocument(segments: segments)
    }
    
    func reparse(_ text: String, in document: ParsedDocument, on change: TextChange) -> ParseResult {
        
        let affectedIndices = document.segments.indices.filter {
            segmentIsAffected(document.segments[$0], by: change.oldRange)
        }
        
        guard let affectedStart = affectedIndices.first,
              let affectedEnd = affectedIndices.last
        else {
            let doc = parse(text)
            return ParseResult(
                document: doc,
                oldSegments: document.segments,
                newSegments: doc.segments,
                affectedRange: TextRange(location: 0, length: text.utf16.count)
            )
        }

        var start = affectedStart
        var end = affectedEnd

        // Expand only when a neighbour exists
        if start > document.segments.startIndex { start -= 1 }
        if end < document.segments.count - 1 { end += 1 }
        
        // Save old segmaents
        let oldSegments = Array(document.segments[start...end])
        let delta = change.newRange.length - change.oldRange.length

        let segmentsRange = TextRange(
            location: oldSegments.first!.range.location,
            length: oldSegments.reduce(0) {
                max($0, $1.range.upperBound)
            } - oldSegments.first!.range.location
        )
        
        let oldRange = segmentsRange.union(change.oldRange)
        let newRange: TextRange
        
        // Making it safe...
        if change.oldRange.length == 0 {
            newRange = TextRange(location: oldRange.location, length: oldRange.length + change.newRange.length)
        } else {
            newRange = TextRange(location: oldRange.location, length: max(0, oldRange.length + delta))
        }
        
        let localText = text.substring(with: newRange)
        let parsedText = parse(localText)
        
        let newSegments = parsedText.segments.map {
            shifted($0, by: newRange.location)
        }
        
        var segments = document.segments
        segments.removeSubrange(start...end)
        segments.insert(contentsOf: newSegments, at: start)
        
        let followingSegmentsStart = start + newSegments.count

        if delta != 0 {
            for i in followingSegmentsStart..<segments.count {
                segments[i] = shifted(segments[i], by: delta)
            }
        }
        
        #if DEBUG
        let full = Parser().parse(text)
        let incremental = ParsedDocument(segments: segments)
        
        if full != incremental {
            harvest("""
            *Change*
            oldRange: \(change.oldRange)
            newRange: \(change.newRange)
            delta: \(change.newRange.length - change.oldRange.length)
            changed text: \(text.substring(with: change.newRange))
            
            FULL PARSE — \(full.segments.map {
                "\($0.speaker): \($0.range) | \($0.textRange)"
            }.joined(separator: "\n"))

            INCREMENTAL — \(incremental.segments.map {
                "\($0.speaker): \($0.range) | \($0.textRange)"
            }.joined(separator: "\n"))

            """)
        }
        #endif
        
        return ParseResult(
            document: ParsedDocument(segments: segments),
            oldSegments: oldSegments,
            newSegments: newSegments,
            affectedRange: newRange
        )
    }
    
    /// Tries to parse a speaker label at the scanner's current paragraph position.
    ///
    /// A label has the form `Speaker: text`.
    private func parseSpeaker(_ text: String, scanner: inout Scanner) -> SpeakerLabel? {
        
        // Get current position
        let labelStart = scanner.position
        
        guard let firstCharacter = scanner.peek(),
              !firstCharacter.isNewline,
              !firstCharacter.isWhitespace
        else { return nil }
        
        var sc = scanner
        var colonPosition: Int?
        
        // Let's find a colon position
        while let character = sc.peek() {
            if character.isColon {
                
                guard let prevChar = sc.peek(offset: -1), !prevChar.isEscapeCharacter
                else {
                    sc.advance()
                    continue
                }
                
                colonPosition = sc.position
                break
            }
            
            if character.isNewline { return nil }
            sc.advance()
        }
        
        guard let colonPosition else { return nil }
        
        let labelLength = colonPosition - labelStart
        guard labelLength > 0 else { return nil }
        
        let speakerRange = TextRange(location: labelStart, length: labelLength)
        let speaker = substring(text, range: speakerRange)
        
        //  Since the colon's position was found earlier using a `sc` scanner, this loop catches the main scanner up to that point.
        while scanner.position <= colonPosition {
            scanner.advance()
        }
        
        //  Skip any whitespace (like spaces or tabs) that might appear between the colon and the start of the actual text.
        while let character = scanner.peek(), character.isWhitespace {
            scanner.advance()
        }
        
        return SpeakerLabel(
            speaker: speaker,
            rangeStart: labelStart,
            speakerRange: speakerRange,
            textStart: scanner.position
        )
    }
    
    private func segmentIsAffected(_ segment: Segment, by range: TextRange) -> Bool {
        if range.length == 0 {
            return segment.range.contains(range.location)
                || segment.range.upperBound == range.location
        }

        return segment.range.location < range.upperBound
                && range.location < segment.range.upperBound
    }
    
    private func shifted(_ segment: Segment, by offset: Int) -> Segment {
        Segment(
            speaker: segment.speaker,
            range: segment.range.shifted(by: offset),
            speakerRange: segment.speakerRange.shifted(by: offset),
            textRange: segment.textRange.shifted(by: offset)
        )
    }
}

nonisolated extension Parser {
    nonisolated struct SpeakerLabel {
        let speaker: String
        let rangeStart: Int
        let speakerRange: TextRange
        let textStart: Int
    }
}

nonisolated private extension Parser {
    
    /// Extracts a string from a UTF-16 range.
    func substring(_ text: String, range: TextRange) -> String {
        let utf16 = text.utf16

        guard range.location >= 0,
              range.length >= 0,
              range.location + range.length <= utf16.count
        else { return "" }

        let start = utf16.index(utf16.startIndex, offsetBy: range.location)
        let end = utf16.index(start, offsetBy: range.length)

        return String(decoding: utf16[start..<end], as: UTF16.self)
    }
    
    /// Returns the end of spoken text without trailing line breaks.
    func textEnd(in text: String, from start: Int, to end: Int) -> Int {
        var result = end
        while result > start {
            let index = text.utf16.index(text.utf16.startIndex, offsetBy: result - 1)
            guard text.utf16[index].isNewline else { break }
            result -= 1
        }
        return result
    }
}

// Kõik saab ükskord läbi: nii hea kui ka halb...
