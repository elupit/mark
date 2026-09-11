//
//  TextRange.swift
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

/// A UTF-16 range inside the document.
struct TextRange: Sendable, Equatable {
    let location: Int
    let length: Int

    /// The first position immediately after the range.
    var upperBound: Int { location + length }

    static let zero = TextRange(location: 0, length: 0)
}
