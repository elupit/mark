//
//  SpeakerView.swift
//  Mark
//
//  Created by Mikhail Korzh on 12.09.2026.
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

import SwiftUI

struct SpeakerView: View {
    let speakers: [String]
    @Binding var speakerData: SpeakerDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if speakers.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Speakers",
                    systemImage: "person.2",
                    description: Text("No speaker markers were found in this document.")
                )
                .padding()
            } else {
                VStack {
                    Text("Speakers")
                        .font(.headline)
                        .padding()
                    List(speakers, id: \.self) { speaker in
                        HStack {
                            Image(systemName: "person")
                                .foregroundStyle(.secondary)
                            Text(speaker)
                            Spacer()
                            Picker("", selection: Binding(
                                get: {
                                    speakerData.data(for: speaker)?.role
                                },
                                set: { role in
                                    if let role {
                                        speakerData.set(SpeakerData(role: role), for: speaker)
                                    } else {
                                        speakerData.removeData(for: speaker)
                                    }
                                })
                            ) {
                                Text("Not assigned").tag(SpeakerRole?.none)
                                Text("Interviewer").tag(SpeakerRole?.some(.interviewer))
                                Text("Informant").tag(SpeakerRole?.some(.informant))
                            }
                            .labelsHidden()
                            .fixedSize()
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
        }
        .frame(width: 450, height: 300)
    }
}

#Preview {
    SpeakerView(
        speakers: [
            "INTERVIEWER",
            "ANNA",
            "MICHAEL"
        ],
        speakerData: .constant(
            SpeakerDataStore(
                speakers: [
                    "INTERVIEWER": SpeakerData(role: .interviewer),
                    "ANNA": SpeakerData(role: .informant)
                ]
            )
        )
    )
}

#Preview("No Speakers") {
    SpeakerView(
        speakers: [],
        speakerData: .constant(
            SpeakerDataStore()
        )
    )
}
