//
//  ParagraphSpacing.swift
//  Mark
//
//  Created by Mikhail Korzh on 07.10.2026.
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

enum ParagraphSpacing: String, CaseIterable, Identifiable {
    case veryCompact
    case compact
    case normal
    case spacious
    case verySpacious

    var id: Self { self }

    var multiplier: Double {
        switch self {
        case .veryCompact: return 0
        case .compact: return 0.5
        case .normal: return 1
        case .spacious: return 1.5
        case .verySpacious: return 2
        }
    }

    var title: String {
        switch self {
        case .veryCompact: return "Very compact"
        case .compact: return "Compact"
        case .normal: return "Default"
        case .spacious: return "Spacious"
        case .verySpacious: return "Very spacious"
        }
    }
}
