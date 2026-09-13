//
//  ColorPicker.swift
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

struct ColorPicker: View {
    @Binding var selection: SpeakerColor?

    var body: some View {
        HStack(spacing: 6) {
            colorButton(nil)

            ForEach(SpeakerColor.allCases, id: \.self) {
                colorButton($0)
            }
        }
    }

    private func colorButton(_ color: SpeakerColor?) -> some View {
        let isSelected = selection == color

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = color
            }
        } label: {
            Circle()
                .fill(color?.color ?? .black)
                .stroke(Color.black, style: StrokeStyle(
                    lineWidth: 0.25,
                ))
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .fill(.white)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isSelected ? 1 : 0)
                        .opacity(isSelected ? 1 : 0)
                }
        }
        .buttonStyle(.plain)
    }
}
