//
//  EditorSettingsView.swift
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

struct EditorSettingsView: View {
    @AppStorage("editor.interviewerBold")
    private var interviewerBold = true
    
    @AppStorage("editor.interviewerUnderline")
    private var interviewerUnderline = false
    
    var body: some View {
        Form {
            Section("Formatting") {
                HStack {
                    Text("Interviewer speech style")
                    Spacer()
                    Toggle(isOn: $interviewerBold) {
                        Text("B").bold()
                    }
                    .toggleStyle(.button)
                    Toggle(isOn: $interviewerUnderline) {
                        Text("U").underline()
                    }
                    .toggleStyle(.button)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500)
    }
}

#Preview {
    EditorSettingsView()
}
