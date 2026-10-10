//
//  HighlightColorPicker.swift
//  Mark
//
//  Created by Mikhail Korzh on 10.10.2026.
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

struct HighlightColorPicker: View {
    let title: String
    @Binding var selection: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            ForEach(HighlightColor.allCases) { highlight in
                Button {
                    selection = highlight.rawValue
                } label: {
                    Circle()
                        .fill(Color(nsColor: highlight.color))
                        .frame(width: 18, height: 18)
                        .overlay {
                            if selection == highlight.rawValue {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(width: 20, height: 20)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(highlight.title)
                .accessibilityAddTraits(
                    selection == highlight.rawValue ? .isSelected : []
                )
                //.animation(.easeInOut(duration: 0.15), value: selection)
            }
        }
    }
}
