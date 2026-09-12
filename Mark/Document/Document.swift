//
//  Document.swift
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

import SwiftUI
import UniformTypeIdentifiers

nonisolated struct Document: FileDocument {
    var text: String
    var meta: Metadata

    init(text: String = "", meta: Metadata = Metadata()) {
        self.text = text
        self.meta = meta
    }

    static let readableContentTypes = [
        UTType(importedAs: "UTType.plain-text")
    ]

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let serializedText = Serializer.read(string)
        text = serializedText.text
        meta = serializedText.meta
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let document = SerializedDocument(text: text, meta: meta)
        let documentAsString = Serializer.write(document)
        guard let data = documentAsString.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return .init(regularFileWithContents: data)
        
    }
}
