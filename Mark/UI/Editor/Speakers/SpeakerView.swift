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
    
    let onSpeakerDataChange: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var speakerDetails: String?

    var body: some View {
        VStack(spacing: 0) {

            if speakers.isEmpty {
                ContentUnavailableView(
                    "No Speakers",
                    systemImage: "person.2",
                    description: Text(
                        "No speaker markers were found in this document."
                    )
                )
                .frame(maxHeight: .infinity)

            } else {
                Form {
                    Section("Speakers") {
                        ForEach(speakers, id: \.self) { speaker in
                            HStack {
                                Label(
                                    speaker,
                                    systemImage: "person"
                                )

                                Spacer()

                                Picker(
                                    "",
                                    selection: Binding(
                                        get: {
                                            speakerData.data(
                                                for: speaker
                                            )?.role
                                        },
                                        set: { role in
                                            let notes = speakerData
                                                .data(for: speaker)?
                                                .notes

                                            if let role {
                                                speakerData.set(
                                                    SpeakerData(
                                                        role: role,
                                                        notes: notes
                                                    ),
                                                    for: speaker
                                                )
                                            } else if let notes {
                                                speakerData.set(
                                                    SpeakerData(
                                                        role: nil,
                                                        notes: notes
                                                    ),
                                                    for: speaker
                                                )
                                            } else {
                                                speakerData.removeData(
                                                    for: speaker
                                                )
                                            }

                                            onSpeakerDataChange(speaker)
                                        }
                                    )
                                ) {
                                    Text("Not assigned").tag(SpeakerRole?.none)
                                    Text("Interviewer").tag(SpeakerRole?.some(.interviewer))
                                    Text("Informant").tag(SpeakerRole?.some(.informant))
                                }
                                .labelsHidden()

                                Button {
                                    speakerDetails = speaker
                                } label: {
                                    Image(systemName: "info.circle")
                                }
                                .buttonStyle(.borderless)
                                .popover(
                                    isPresented: Binding(
                                        get: {
                                            speakerDetails == speaker
                                        },
                                        set: { isPresented in
                                            if !isPresented {
                                                speakerDetails = nil
                                            }
                                        }
                                    )
                                ) {
                                    SpeakerDetailsView(
                                        speaker: speaker,
                                        speakerData: $speakerData
                                    )
                                }
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .frame(maxHeight: .infinity)
            }

            Divider()

            HStack {
                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 450, height: 300)
    }
}

#Preview("With Speakers") {
    SpeakerView(
        speakers: [
            "INTERVIEWER",
            "ANNA",
            "MICHAEL"
        ],
        speakerData: .constant(
            SpeakerDataStore(
                speakers: [
                    "INTERVIEWER": SpeakerData(
                        role: .interviewer
                    ),
                    "ANNA": SpeakerData(
                        role: .informant,
                        notes: "Mother of the child. Interviewed twice."
                    ),
                    "MICHAEL": SpeakerData(
                        role: .informant
                    )
                ]
            )
        ),
        onSpeakerDataChange: { _ in }
    )
}

#Preview("No Speakers") {
    SpeakerView(
        speakers: [],
        speakerData: .constant(
            SpeakerDataStore()
        ),
        onSpeakerDataChange: { _ in }
    )
}
