//
//  IncrementalParser.swift
//  Mark
//
//  Created by Mikhail Korzh on 15.09.2026.
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

nonisolated struct IncrementalParser {
    private let parser = Parser()
    
    /// Re-parses the segment affected by a text change.
    func update(
        text: String,
        document: ParsedDocument,
        change: TextChange
    ) -> ParsedDocument {
        guard let firstIndex = affectedSegmentIndex(
            in: document,
            change: change
        ) else {
            return parser.parse(text)
        }
        
        let lastIndex = lastAffectedSegmentIndex(
            in: document,
            change: change,
            firstIndex: firstIndex
        )
        
        // Include the previous segment when a boundary is removed.
        let startIndex: Int
        
        if firstIndex > 0,
           document.segments[firstIndex].range.location == change.oldRange.location {
            startIndex = firstIndex - 1
        } else {
            startIndex = firstIndex
        }
        
        let oldEnd = document.segments[lastIndex].range.upperBound
        let startSegment = document.segments[startIndex]
        
        let affectedRange = TextRange(
            location: startSegment.range.location,
            length: oldEnd - startSegment.range.location
        )
        
        let newRange = updatedRange(affectedRange, for: change)
        let localText = parser.substring(text, range: newRange)
        let parsed = parser.parse(localText)
        
        var segments = document.segments
        segments.removeSubrange(startIndex...lastIndex)
        
        let newSegments = parsed.segments.map {
            shifted($0, by: newRange.location)
        }
        
        segments.insert(contentsOf: newSegments, at: startIndex)
        
        // Shift all segments after the reparsed range.
        let delta = change.newRange.length - change.oldRange.length
        
        if delta != 0 {
            for i in (startIndex + newSegments.count)..<segments.count {
                segments[i] = shifted(segments[i], by: delta)
            }
        }
        
        return ParsedDocument(segments: segments)
    }
    
    /// Finds the segment containing the changed text or insertion point.
    private func affectedSegmentIndex(
        in document: ParsedDocument,
        change: TextChange
    ) -> Int? {
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
    
    /// Finds the last segment touched by a text change.
    private func lastAffectedSegmentIndex(
        in document: ParsedDocument,
        change: TextChange,
        firstIndex: Int
    ) -> Int {
        guard !change.oldRange.isEmpty else {
            return firstIndex
        }
        
        let oldEnd = change.oldRange.upperBound
        
        return document.segments.lastIndex {
            $0.range.location < oldEnd
        } ?? firstIndex
    }
    
    /// Adjusts an old range to its position in the new text.
    private func updatedRange(
        _ range: TextRange,
        for change: TextChange
    ) -> TextRange {
        let delta = change.newRange.length - change.oldRange.length
        
        if range.upperBound < change.oldRange.location {
            return range
        }
        
        if range.location > change.oldRange.upperBound {
            return TextRange(
                location: range.location + delta,
                length: range.length
            )
        }
        
        return TextRange(
            location: range.location,
            length: range.length + delta
        )
    }
    
    /// Converts a locally parsed segment into an absolute document segment.
    private func shifted(
        _ segment: Segment,
        by offset: Int
    ) -> Segment {
        Segment(
            speaker: segment.speaker,
            range: shifted(segment.range, by: offset),
            speakerRange: shifted(segment.speakerRange, by: offset),
            textRange: shifted(segment.textRange, by: offset)
        )
    }
    
    /// Shifts a UTF-16 range by a document offset.
    private func shifted(
        _ range: TextRange,
        by offset: Int
    ) -> TextRange {
        TextRange(
            location: range.location + offset,
            length: range.length
        )
    }
}
