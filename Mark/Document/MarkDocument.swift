//
//  MarkDocument.swift
//  Mark
//
//  Created by Mikhail Korzh on 20.09.2026.
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

import SwiftUI
import UniformTypeIdentifiers

@Observable
final class MarkDocument: Document {
    
    static let readableContentTypes: [UTType] = [.mark]
    
    var text: String
    var meta: Metadata
    
    init(text: String = "", meta: Metadata = Metadata()) {
        self.text = text
        self.meta = meta
    }
    
    nonisolated func reader(configuration: sending ReadConfiguration) ->
    sending FileWrapperDocumentReader<MarkSnapshot> {
        FileWrapperDocumentReader(configuration) { fileWrapper in
            
            guard let data = fileWrapper.regularFileContents
                    else {
                throw CocoaError(.fileReadCorruptFile)
            }
            
            let string = String(decoding: data, as: UTF8.self)
            guard let block = Self.findMeta(in: string)
                    else {
                return MarkSnapshot(text: string, meta: Metadata())
            }
            
            let text = String(string[..<block.lowerBound])
            let json = String(string[block.jsonRange])
            
            let meta = (try? JSONDecoder().decode(Metadata.self, from: Data(json.utf8))) ?? Metadata()
            
            return MarkSnapshot(text: text, meta: meta)
        }
    }
    
    nonisolated func writer(configuration: sending WriteConfiguration) ->
    sending FileWrapperDocumentWriter<MarkSnapshot> {
        FileWrapperDocumentWriter(configuration) { snapshot, _ in
            FileWrapper(
                regularFileWithContents: Self.fileContent(from: snapshot)
            )
        }
    }
    
    @MainActor
    func snapshot(contentType: UTType) async throws -> sending MarkSnapshot {
        return MarkSnapshot(text: text, meta: meta)
    }
    
    @MainActor
    func apply(snapshot: sending MarkSnapshot, previous: sending MarkSnapshot?) async throws {
        text = snapshot.text
        meta = snapshot.meta
    }
    
    // MARK: - Metadata
    
    /// Searches for the metadata block within the given text.
    ///
    /// This method looks for the metadata start and end markers, ensuring the end marker
    /// is at the very end of the text (ignoring trailing whitespace).
    ///
    /// - Parameter text: The document text to search.
    /// - Returns: A `MetaBlock` containing the ranges of the metadata, or `nil` if not found.
    nonisolated private static func findMeta(in text: String) -> MetaBlock? {
        guard let closing = text.range(of: MetaBlockFormat.endMarker, options: .backwards)
                else { return nil }
        
        guard text[closing.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
                else { return nil }
        
        guard let opening = text.range(
            of: MetaBlockFormat.startMarker,
            options: .backwards,
            range: text.startIndex..<closing.lowerBound
        ) else { return nil }
        
        return MetaBlock(
            lowerBound: opening.lowerBound,
            jsonRange: opening.upperBound..<closing.lowerBound
        )
    }
}

nonisolated extension MarkDocument {
    
    nonisolated private static func fileContent(from snapshot: MarkSnapshot) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard
            let data = try? encoder.encode(snapshot.meta),
            let json = String(data: data, encoding: .utf8)
        else {
            return Data(snapshot.text.utf8)
        }

        let content =
            snapshot.text
            + MetaBlockFormat.startMarker
            + json
            + MetaBlockFormat.endMarker

        return Data(content.utf8)
    }
}

// MARK: - Helpers

/// A snapshot of the document's current state, including its text content and associated metadata.
/// Conforms to `Sendable` to allow safe concurrent access across actors.
struct MarkSnapshot: Sendable {
    let text: String
    let meta: Metadata
}

/// Defines the boundaries for the internal metadata block within a document.
/// These markers are used to separate the document's text content from its hidden metadata layer.
private enum MetaBlockFormat {
    nonisolated static let startMarker =
        "\n\n/* MARK SECTION START\n" +
        "\nWhoops! You've stumbled into the secret depths of Mark's internal data layer. Unless you're a wizard who knows exactly what they're doing, it's best to leave this part untouched!\n\n"

    nonisolated static let endMarker = "\n\nMARK SECTION END */"
}

/// Represents the location of the metadata block within the document's text.
private struct MetaBlock: Sendable {
    /// The starting index of the metadata block.
    let lowerBound: String.Index
    /// The range of the JSON payload within the metadata block.
    let jsonRange: Range<String.Index>
}

extension UTType {
    /// The custom uniform type identifier for a Mark document.
    static var mark: UTType {
        UTType(importedAs: "mark.document")
    }
}
