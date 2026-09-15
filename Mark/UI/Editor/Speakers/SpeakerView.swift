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
    @State private var showRemoveConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Speakers") {
                    if speakers.isEmpty {
                        Label("No speaker markers were found in this document.",
                              systemImage: "person.2.slash")
                        .foregroundStyle(.secondary)
                    } else {
                        ForEach(speakers, id: \.self) { speaker in
                            HStack {
                                Label(speaker,
                                      systemImage: "person")
                                
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
                                            let currentData = speakerData.data(for: speaker)
                                            
                                            let notes = currentData?.notes
                                            let color = currentData?.color
                                            
                                            if let role {
                                                speakerData.set(
                                                    SpeakerData(
                                                        role: role,
                                                        color: color,
                                                        notes: notes
                                                    ),
                                                    for: speaker
                                                )
                                            } else if notes != nil || color != nil {
                                                speakerData.set(
                                                    SpeakerData(
                                                        role: nil,
                                                        color: color,
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
                                .scaledToFit()
                                
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
                                        speakerData: $speakerData,
                                        onSpeakerDataChange: {
                                            onSpeakerDataChange(speaker)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Text("Speaker information is saved at the end of the file. Hidden when editing in Mark, and visible in other apps.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    HStack {
                        Spacer()
                        Button("Remove Speaker Information…") {
                            showRemoveConfirmation = true
                        }
                        .confirmationDialog("Remove speaker information?", isPresented: $showRemoveConfirmation) {
                            Button("Remove", role: .destructive) {
                                speakerData = SpeakerDataStore()
                                speakers.forEach(onSpeakerDataChange)
                            }
                            
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will remove all speaker information added to this document.")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: .infinity)

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
                        color: .pink,
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
