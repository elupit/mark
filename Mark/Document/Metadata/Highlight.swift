//
//  Highlight.swift
//  Mark
//
//  Created by Mikhail Korzh on 08.10.2026.
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

struct Highlight: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    var range: TextRange
    var comment: String?

    init(_ range: TextRange, comment: String? = nil) {
        self.id = UUID()
        self.range = range
        self.comment = comment
    }

    nonisolated static func == (lhs: Highlight, rhs: Highlight) -> Bool {
        lhs.id == rhs.id
    }
}
