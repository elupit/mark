//
//  Presentation.swift
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
import AppKit

/// Applies the visual presentation of the parsed document to the text view.
struct Presentation {

    /// Removes old speaker formatting from the affected paragraph and reapplies current formatting.
    func apply(
        _ parsedDocument: ParsedDocument,
        to textView: NSTextView,
        paragraphRange: NSRange,
        speakerData: SpeakerDataStore
    ) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let regularFont = NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        )

        let boldFont = NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .bold
        )

        let length = textStorage.length

        guard length > 0 else {
            return
        }

        let location = min(
            max(paragraphRange.location, 0),
            length
        )

        let safeParagraphRange = NSRange(
            location: location,
            length: min(
                max(paragraphRange.length, 0),
                length - location
            )
        )

        guard safeParagraphRange.length > 0 else {
            return
        }

        textStorage.beginEditing()

        textStorage.addAttribute(
            .font,
            value: regularFont,
            range: safeParagraphRange
        )

        for segment in parsedDocument.segments {

            let segmentRange = NSRange(
                location: segment.range.location,
                length: segment.range.length
            )

            guard NSIntersectionRange(
                segmentRange,
                safeParagraphRange
            ).length > 0 else {
                continue
            }

            guard segmentRange.location >= 0,
                  segmentRange.location + segmentRange.length <= length
            else {
                continue
            }

            let speakerRange = NSRange(
                location: segment.speakerRange.location,
                length: segment.speakerRange.length
            )

            // Every speaker marker is bold.
            textStorage.addAttribute(
                .font,
                value: boldFont,
                range: speakerRange
            )

            // The entire interviewer's segment is bold.
            if speakerData.data(for: segment.speaker)?.role == .interviewer {
                textStorage.addAttribute(
                    .font,
                    value: boldFont,
                    range: segmentRange
                )
            }
        }

        textStorage.endEditing()
    }
    
    func rerenderSpeaker(
        _ speaker: String,
        in parsedDocument: ParsedDocument,
        to textView: NSTextView,
        speakerData: SpeakerDataStore
    ) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let regularFont = NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        )

        let boldFont = NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .bold
        )

        let length = textStorage.length

        textStorage.beginEditing()

        for segment in parsedDocument.segments
            where segment.speaker == speaker {

            let segmentRange = NSRange(
                location: segment.range.location,
                length: segment.range.length
            )

            guard segmentRange.location >= 0,
                  segmentRange.location + segmentRange.length <= length
            else {
                continue
            }

            textStorage.addAttribute(
                .font,
                value: regularFont,
                range: segmentRange
            )

            let speakerRange = NSRange(
                location: segment.speakerRange.location,
                length: segment.speakerRange.length
            )

            textStorage.addAttribute(
                .font,
                value: boldFont,
                range: speakerRange
            )

            if speakerData.data(for: speaker)?.role == .interviewer {
                textStorage.addAttribute(
                    .font,
                    value: boldFont,
                    range: segmentRange
                )
            }
        }

        textStorage.endEditing()
    }
}
