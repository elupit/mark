//
//  UInt16.swift
//  Mark
//
//  Created by Mikhail Korzh on 27.09.2026.
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

nonisolated extension UInt16 {
    /// Returns `true` for LF and CR line breaks.
    var isNewline: Bool {
        self == 10 || self == 13
    }

    /// Returns `true` for spaces and tabs.
    var isWhitespace: Bool {
        self == 32 || self == 9 || self == 160
    }
    
    /// Returns `true` for colon.
    var isColon: Bool {
        self == 58
    }
    
    var isEscapeCharacter: Bool {
        self == 92
    }
}
