//
//  Scanner.swift
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

/// A UTF-16 scanner.
///
/// The scanner provides sequential access to the requested part of the document.
nonisolated struct Scanner {
    
    /// The underlying UTF-16 code units being scanned.
    private let units: String.UTF16View
    /// The current position in the UTF-16 view.
    private var index: String.UTF16View.Index
    /// The absolute end position of the scanner within the document.
    private let endPosition: Int
    /// The current absolute position of the scanner.
    private(set) var position: Int

    /// Creates a scanner for the complete document.
    init(_ text: String) {
        self.units = text.utf16
        self.index = units.startIndex
        self.endPosition = units.count
        self.position = 0
    }

    /// Creates a scanner for a UTF-16 range while preserving absolute positions.
    ///
    /// The range is clamped to the actual document boundaries.
    init(_ text: String, range: TextRange) {
        self.units = text.utf16

        let documentLength = units.count
        let start = min(max(range.location, 0), documentLength)
        let end = min(max(range.upperBound, start), documentLength)

        self.index = units.index(units.startIndex, offsetBy: start)
        self.endPosition = end
        self.position = start
    }

    /// Returns true when the scanner reached the end of its range.
    var isAtEnd: Bool {
        position >= endPosition || index == units.endIndex
    }

    /// Returns the current UTF-16 code unit without advancing.
    func peek() -> UInt16? {
        guard !isAtEnd else { return nil }
        return units[index]
    }

    /// Returns a UTF-16 code unit at an offset without advancing.
    func peek(offset: Int) -> UInt16? {
        guard position + offset >= 0,
              position + offset < endPosition else {
            return nil
        }

        var current = index

        if offset >= 0 {
            for _ in 0..<offset {
                current = units.index(after: current)
            }
        } else {
            for _ in 0..<(-offset) {
                current = units.index(before: current)
            }
        }

        return units[current]
    }

    /// Advances the scanner by one UTF-16 code unit.
    @discardableResult
    mutating func advance() -> UInt16? {
        guard !isAtEnd else { return nil }

        let character = units[index]
        index = units.index(after: index)
        position += 1

        return character
    }
}
