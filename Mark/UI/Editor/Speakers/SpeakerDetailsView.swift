//
//  SpeakerDetailsView.swift
//  Mark
//
//  Created by Mikhail Korzh on 13.09.2026.
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

struct SpeakerDetailsView: View {

    let speaker: String
    @Binding var speakerData: SpeakerDataStore

    @State private var notes = ""
    @State private var color: SpeakerColor?
    
    let onSpeakerDataChange: () -> Void

    var body: some View {
        Form {
            Section("Color") {
                ColorPicker(selection: $color)
                .onChange(of: color) {
                    let current = speakerData.data(for: speaker)

                    if current?.role != nil || current?.notes != nil || color != nil {
                        speakerData.set(
                            SpeakerData(
                                role: current?.role,
                                color: color,
                                notes: current?.notes
                            ),
                            for: speaker
                        )
                    } else {
                        speakerData.removeData(for: speaker)
                    }

                    onSpeakerDataChange()
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .scrollContentBackground(.hidden)
                    .frame(height: 80)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(width: 320, height: 270)
        .onAppear {
            let current = speakerData.data(for: speaker)
            notes = current?.notes ?? ""
            color = current?.color
        }
        .onChange(of: notes) {
            let current = speakerData.data(for: speaker)

            if notes.isEmpty {
                if current?.role != nil || color != nil {
                    speakerData.set(
                        SpeakerData(role: current?.role, color: color),
                        for: speaker
                    )
                } else {
                    speakerData.removeData(for: speaker)
                }
            } else {
                speakerData.set(
                    SpeakerData(
                        role: current?.role,
                        color: color,
                        notes: notes
                    ),
                    for: speaker
                )
            }
        }
    }
}

#Preview {
    SpeakerDetailsView(
        speaker: "ANNA",
        speakerData: .constant(
            SpeakerDataStore(
                speakers: [
                    "ANNA": SpeakerData(
                        role: .informant,
                        color: .blue,
                        notes: "Mother of the child. Interviewed twice."
                    )
                ]
            )
        ),
        onSpeakerDataChange: {}
    )
}
