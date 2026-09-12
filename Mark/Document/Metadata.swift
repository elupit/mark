//
//  Metadata.swift
//  Mark
//
//  Created by Mikhail Korzh on 08.09.2026.
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

nonisolated struct Metadata: Codable, Sendable {
    var caretPosition: Int?
    var isLocked: Bool
    var speakerData: SpeakerDataStore

    init(
        caretPosition: Int? = nil,
        isLocked: Bool = false,
        speakerData: SpeakerDataStore = SpeakerDataStore()
    ) {
        self.caretPosition = caretPosition
        self.isLocked = isLocked
        self.speakerData = speakerData
    }
    
    enum CodingKeys: String, CodingKey {
        case caretPosition
        case isLocked
        case speakerData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        caretPosition = try container.decodeIfPresent(Int.self, forKey: .caretPosition)
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        speakerData = try container.decodeIfPresent(SpeakerDataStore.self, forKey: .speakerData) ?? SpeakerDataStore()
    }
}
