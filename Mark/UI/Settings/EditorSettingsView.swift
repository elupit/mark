//
//  EditorSettingsView.swift
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
import AppKit

struct EditorSettingsView: View {

    @AppStorage(DefaultKeys.Editor.fontSize) private var fontSize = 13.0
    private let minFontSize: Double = 10
    private let maxFontSize: Double = 22

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Slider(
                        value: $fontSize,
                        in: minFontSize...maxFontSize,
                        step: 3,
                        label: {
                            Text("Font Size")
                        },
                        minimumValueLabel: {
                            Text("A")
                                .font(.system(size: minFontSize))
                                .padding(.horizontal, 4)
                        },
                        maximumValueLabel: {
                            Text("A")
                                .font(.system(size: maxFontSize))
                                .padding(.horizontal, 4)
                        }
                    )
                    .frame(width: 300)
                    .labelsHidden()
                }
                //.padding(.top, 8)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    EditorSettingsView()
}
