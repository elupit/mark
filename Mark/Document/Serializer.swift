//
//  Serializer.swift
//  Mark
//
//  Created by Mikhail Korzh on 07.09.2026.
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

struct Serializer: Sendable {
    
    nonisolated static func read(_ text: String) -> SerializedDocument {
        guard let infoBlock = findMeta(in: text) else {
            return SerializedDocument(text: text, meta: Metadata())
        }
        
        let documentText = String(text[..<infoBlock.lowerBound])
        let info = String(text[infoBlock.jsonRange])
        
        let infoData = try? JSONDecoder().decode(
            Metadata.self,
            from: Data(info.utf8)
        )
        
        return SerializedDocument(
            text: documentText,
            meta: infoData ?? Metadata()
        )
    }
    
    nonisolated static func write(_ document: SerializedDocument) -> String {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(document.meta),
              let json = String(data: data, encoding: .utf8)
        else { return document.text }
        
        return document.text + MetaBlockFormat.startMarker + json + MetaBlockFormat.endMarker
    }
    
    // MARK: - Metadata
    
    nonisolated private static func findMeta(in text: String) -> MetaBlock? {
        guard let closing = text.range(of: MetaBlockFormat.endMarker, options: .backwards)
        else { return nil }
        
        guard text[closing.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        else { return nil }
        
        guard let opening = text.range(of: MetaBlockFormat.startMarker, options: .backwards, range: text.startIndex..<closing.lowerBound)
        else { return nil }
        
        return MetaBlock(lowerBound: opening.lowerBound, jsonRange: opening.upperBound..<closing.lowerBound)
    }
}

private nonisolated enum MetaBlockFormat {

    static let startMarker: String = "\n/* MARK SECTION START\n" +
    "You probably weren't supposed to see this. This section belongs to Mark's internal data layer. Please don't edit it unless you know exactly what you're doing.\n"

    static let endMarker: String = "\nMARK SECTION END */"
}

private struct MetaBlock: Sendable {
    let lowerBound: String.Index
    let jsonRange: Range<String.Index>
}
