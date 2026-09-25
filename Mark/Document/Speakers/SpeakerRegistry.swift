//
//  SpeakerRegistry.swift
//  Mark
//
//  Created by Mikhail Korzh on 24.09.2026.
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

@Observable
final class SpeakerRegistry {
    private(set) var speakers: [Speaker] = []
    private var usageCount: [String: Int] = [:]

    /// Adds speakers from a complete parsed document.
    func setDocument(_ document: ParsedDocument) {
        speakers = []
        usageCount = [:]

        add(document.segments)
    }

    /// Updates speakers using only the segments replaced by an edit.
    func update(removing oldSegments: [Segment], adding newSegments: [Segment]) {
        remove(oldSegments)
        add(newSegments)
    }

    private func add(_ segments: [Segment]) {
        for segment in segments {
            let name = segment.speaker

            usageCount[name, default: 0] += 1

            guard !speakers.contains(where: { $0.name == name }) else {
                continue
            }

            speakers.append(Speaker(name: name))
        }
    }

    private func remove(_ segments: [Segment]) {
        for segment in segments {
            let name = segment.speaker

            guard let count = usageCount[name] else {
                continue
            }

            if count <= 1 {
                usageCount.removeValue(forKey: name)
                speakers.removeAll { $0.name == name }
            } else {
                usageCount[name] = count - 1
            }
        }
    }
}
