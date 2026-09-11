//
//  Segment.swift
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

/// A segment of an interview transcript.
///
/// A segment starts with a speaker marker and continues until
/// another speaker marker or the end of the document.
struct Segment: Sendable, Equatable {
    /// The speaker label without the colon.
    let speaker: String
    /// The complete segment, including the speaker marker.
    let range: TextRange
    /// The speaker label, excluding the colon.
    let speakerRange: TextRange
    /// The spoken text, excluding the speaker label and trailing line breaks.
    let textRange: TextRange
}
