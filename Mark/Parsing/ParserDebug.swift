//
//  ParserDebug.swift
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

#if DEBUG

import AppKit
import Foundation

nonisolated enum ParserDebug {

    private static let maxEntries = 5

    private static var fileURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("Mark Parser Debug.txt")
    }

    static func recordFull(
        text: String,
        segments: [Segment]
    ) {
        let entry = """
        ===== FULL — \(timestamp()) =====

        TEXT
        \(text.debugDescription)

        SEGMENTS
        \(describe(segments))

        """

        append(entry)
    }

    static func recordIncremental(
        text: String,
        change: TextChange,
        oldSegments: [Segment],
        newSegments: [Segment]
    ) {
        let entry = """
        ===== INCREMENTAL — \(timestamp()) =====

        CHANGE
        oldRange: \(change.oldRange)
        newRange: \(change.newRange)

        TEXT
        \(text.debugDescription)

        OLD SEGMENTS
        \(describe(oldSegments))

        NEW SEGMENTS
        \(describe(newSegments))

        """

        append(entry)
    }

    static func openHistory() {
        NSWorkspace.shared.open(fileURL)
    }

    private static func append(_ entry: String) {
        let history = (try? String(
            contentsOf: fileURL,
            encoding: .utf8
        )) ?? ""

        let entries = history
            .components(separatedBy: "===== ")
            .dropFirst()
            .map { "===== " + $0 }

        let newHistory = ([entry] + Array(entries.prefix(maxEntries - 1)))
            .joined(separator: "\n")

        try? newHistory.write(
            to: fileURL,
            atomically: true,
            encoding: .utf8
        )
    }

    private static func describe(_ segments: [Segment]) -> String {
        guard !segments.isEmpty else {
            return "(none)"
        }

        return segments.enumerated()
            .map { index, segment in
                """
                [\(index)]
                speaker: \(segment.speaker.debugDescription)
                range: \(segment.range)
                speakerRange: \(segment.speakerRange)
                textRange: \(segment.textRange)
                """
            }
            .joined(separator: "\n")
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}

#endif
