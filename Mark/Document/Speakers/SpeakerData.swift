//
//  SpeakerData.swift
//  Mark
//
//  Created by Mikhail Korzh on 25.09.2026.
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

// MARK: - SpeakerDataStore

nonisolated struct SpeakerDataStore: Codable, Sendable, Equatable {

    var speakers: [String: SpeakerData] = [:]

    func data(for speaker: String) -> SpeakerData? {
        speakers[speaker]
    }

    func role(for speaker: String) -> SpeakerRole? {
        speakers[speaker]?.role
    }

    mutating func update(_ data: SpeakerData?, for speaker: String) {
        if let data, !data.isEmpty {
            speakers[speaker] = data
        } else {
            speakers.removeValue(forKey: speaker)
        }
    }

    mutating func updateRole(_ role: SpeakerRole?, for speaker: String) {
        var data = speakers[speaker] ?? SpeakerData()
        data.role = role

        update(data, for: speaker)
    }
    
    func isInterviewer(_ speaker: String) -> Bool {
        role(for: speaker) == .interviewer
    }
}

// MARK: - SpeakerData

nonisolated struct SpeakerData: Codable, Sendable, Equatable {
    var role: SpeakerRole?

    var isEmpty: Bool { role == nil }
}

// MARK: - SpeakerRole

nonisolated enum SpeakerRole: String, Codable, Sendable, CaseIterable {
    case interviewer
    case participant
    
    var title: String {
        switch self {
        case .interviewer: "Interviewer"
        case .participant: "Participant"
        }
    }
}
