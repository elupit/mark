//
//  SpeakerSheet.swift
//  Mark
//
//  Created by Mikhail Korzh on 24.09.2026.
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

struct SpeakerSheet: View {

    @Environment(\.dismiss) private var dismiss

    let speakers: SpeakerRegistry
    let onSave: (SpeakerDataStore) -> Void

    @State private var speakerData: SpeakerDataStore

    init(
        speakers: SpeakerRegistry,
        speakerData: SpeakerDataStore,
        onSave: @escaping (SpeakerDataStore) -> Void
    ) {
        self.speakers = speakers
        self.onSave = onSave
        self._speakerData = State(initialValue: speakerData)
    }

    var body: some View {

        VStack(spacing: 0) {
            if speakers.speakers.isEmpty {
                ContentUnavailableView(
                    "No Speakers",
                    systemImage: "person.2",
                    description: Text(
                        "Speakers found in the interview will appear here."
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    Section {
                        ForEach(speakers.speakers) { speaker in
                            HStack {
                                Label(speaker.name, systemImage: "person")
                                Spacer()
                                Picker(speaker.name, selection: roleBinding(for: speaker.name)) {
                                    Text("None").tag(SpeakerRole?.none)
                                    ForEach(SpeakerRole.allCases, id: \.self) { role in
                                        Text(role.title).tag(Optional(role))
                                    }
                                }
                                .labelsHidden()
                                .help("Assign a role to this speaker.")
                            }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Speakers")
                            Text("Assign roles to speakers. Changes are stored in the " +
                                 "document metadata and remain available outside Mark.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollIndicators(.hidden)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Done") {
                    onSave(speakerData)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(idealWidth: 500, minHeight: 300)
    }

    private func roleBinding(for speaker: String) -> Binding<SpeakerRole?> {
        Binding {
            speakerData.role(for: speaker)
        } set: { role in
            speakerData.updateRole(role, for: speaker)
        }
    }
}
