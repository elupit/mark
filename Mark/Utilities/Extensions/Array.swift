//
//  Array.swift
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

import Foundation

extension Array where Element == Segment {

    /// The combined text range of all segments in the array.
    ///
    /// This property calculates the total span from the start of the first segment
    /// to the end of the last segment. Returns `nil` if the array is empty.
    var range: TextRange? {
        guard let first, let last else { return nil }
        return TextRange(location: first.range.location, length: last.range.upperBound - first.range.location)
    }
}
