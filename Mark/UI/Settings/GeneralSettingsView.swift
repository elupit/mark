//
//  GeneralSettingsView.swift
//  Mark
//
//  Created by Mikhail Korzh on 22.09.2026.
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

struct GeneralSettingsView: View {
    
    @State private var showingResetConfirmation = false
    
    var body: some View {
        Form {
            Section("Reset Mark") {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Reset Settings")
                        Spacer()
                        Button("Reset") { showingResetConfirmation = true }
                    }
                    Text("Resets all Mark settings to their default values.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Reset Settings?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { resetSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All Mark settings will be reset to their default values.")
        }
    }
    
    func resetSettings() {
        for key in DefaultSettings.defaults.keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

#Preview {
    GeneralSettingsView()
}
