//
//  TextChange.swift
//  Mark
//
//  Created by Mikhail Korzh on 02.10.2026.
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

/// Represents a change in text, defined by its old and new ranges.
nonisolated struct TextChange: Sendable, Equatable {
    let oldRange: TextRange
    let newRange: TextRange

    func updatedRange(_ range: TextRange) -> TextRange {
        let delta = newRange.length - oldRange.length

        if range.upperBound <= oldRange.location { return range }
        if range.location >= oldRange.upperBound {
            return TextRange(location: range.location + delta, length: range.length)
        }

        return TextRange(location: range.location, length: max(0, range.length + delta))
    }
}
