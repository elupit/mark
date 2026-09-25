//
//  TextRange.swift
//  Mark
//
//  Created by Mikhail Korzh on 23.09.2026.
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

/// A UTF-16 range inside the document.
nonisolated struct TextRange: Sendable, Equatable {
    
    let location: Int
    let length: Int
    
    /// The first position immediately after the range.
    var upperBound: Int { location + length }
    
    /// Whether the range contains no characters.
    var isEmpty: Bool {
        length == 0
    }
    
    /// An `NSRange` representation of the text range.
    ///
    /// This property converts the custom `TextRange` structure into
    /// an `NSRange` object.
    var nsRange: NSRange {
        NSRange(location: location, length: length)
    }
    
    /// Whether this range overlaps another non-empty range.
    func intersects(_ other: TextRange) -> Bool {
        location < other.upperBound && other.location < upperBound
    }
    
    /// Whether this range contains a UTF-16 position.
    func contains(_ position: Int) -> Bool {
        location <= position && position < upperBound
    }
    
    static let zero = TextRange(location: 0, length: 0)
}
