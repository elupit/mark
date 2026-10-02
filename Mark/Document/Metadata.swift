//
//  Metadata.swift
//  Mark
//
//  Created by Mikhail Korzh on 21.09.2026.
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

/// Represents the metadata associated with a document.
nonisolated struct Metadata: Codable, Sendable {
    /// The data store containing speaker information.
    var speakers = SpeakerDataStore()
    /// A boolean value indicating whether the `TextEditorView` content is locked for editing.
    var isLocked = false
}

/// Defines the boundaries for the internal metadata block within a document.
/// These markers are used to separate the document's text content from its hidden metadata layer.
nonisolated enum MetaBlockFormat {
    static let startMarker =
        "\n\n/* MARK SECTION START\n" +
        "\nWhoops! You've stumbled into the secret depths of Mark's internal data layer. Unless you're a wizard who knows exactly what they're doing, it's best to leave this part untouched!\n\n"

    static let endMarker = "\n\nMARK SECTION END */"
}
