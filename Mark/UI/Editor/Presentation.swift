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

/// Applies the visual presentation of the parsed document.
struct Presentation {
    /// Resets formatting in the affected range and reapplies it.
    func apply(
        _ parsedDocument: ParsedDocument,
        to textView: NSTextView,
        paragraphRange: NSRange,
        speakerData: SpeakerDataStore
    ) {
        guard let textStorage = textView.textStorage else { return }

        let regularFont = NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        )
        let boldFont = NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .bold
        )
        let length = textStorage.length

        guard length > 0 else { return }

        let location = min(max(paragraphRange.location, 0), length)
        let safeRange = NSRange(
            location: location,
            length: min(max(paragraphRange.length, 0), length - location)
        )

        guard safeRange.length > 0 else { return }

        textStorage.beginEditing()
        textStorage.addAttribute(.font, value: regularFont, range: safeRange)
        textStorage.removeAttribute(.foregroundColor, range: safeRange)

        for segment in parsedDocument.segments {
            let segmentRange = NSRange(
                location: segment.range.location,
                length: segment.range.length
            )

            guard NSIntersectionRange(segmentRange, safeRange).length > 0,
                  segmentRange.location >= 0,
                  segmentRange.location + segmentRange.length <= length
            else { continue }

            let speakerRange = NSRange(
                location: segment.speakerRange.location,
                length: segment.speakerRange.length
            )

            // Speaker markers are always bold.
            textStorage.addAttribute(.font, value: boldFont, range: speakerRange)

            if let color = speakerData.data(for: segment.speaker)?.color {
                textStorage.addAttribute(
                    .foregroundColor,
                    value: color.nsColor,
                    range: speakerRange
                )
            }

            // Interviewer segments are entirely bold.
            if speakerData.data(for: segment.speaker)?.role == .interviewer {
                textStorage.addAttribute(.font, value: boldFont, range: segmentRange)
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
        guard let textStorage = textView.textStorage else { return }

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

        for segment in parsedDocument.segments where segment.speaker == speaker {
            let segmentRange = NSRange(
                location: segment.range.location,
                length: segment.range.length
            )

            guard segmentRange.location >= 0,
                  segmentRange.location + segmentRange.length <= length
            else { continue }

            textStorage.addAttribute(.font, value: regularFont, range: segmentRange)
            textStorage.removeAttribute(.foregroundColor, range: segmentRange)

            let speakerRange = NSRange(
                location: segment.speakerRange.location,
                length: segment.speakerRange.length
            )

            textStorage.addAttribute(.font, value: boldFont, range: speakerRange)

            if let color = speakerData.data(for: speaker)?.color {
                textStorage.addAttribute(
                    .foregroundColor,
                    value: color.nsColor,
                    range: speakerRange
                )
            }

            if speakerData.data(for: speaker)?.role == .interviewer {
                textStorage.addAttribute(.font, value: boldFont, range: segmentRange)
            }
        }

        textStorage.endEditing()

        if let textContainer = textView.textContainer,
           let layoutManager = textView.layoutManager {
            layoutManager.ensureLayout(for: textContainer)
        }

        textView.needsDisplay = true
    }
}
