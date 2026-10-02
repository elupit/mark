//
//  MarkTextExport.swift
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

import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class MarkTextExport: WritableDocument {
    static let writableContentTypes: [UTType] = [.plainText]

    let text: String
    init(text: String) { self.text = text }

    nonisolated func writer( configuration: sending WriteConfiguration) -> sending FileWrapperDocumentWriter<String> {
        FileWrapperDocumentWriter(configuration) { snapshot, _ in
            FileWrapper(regularFileWithContents: Data(snapshot.utf8))
        }
    }
    
    func snapshot(contentType: UTType) async throws -> sending String { text }
}
