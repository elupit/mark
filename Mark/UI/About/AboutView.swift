//
//  AboutView.swift
//  Mark
//
//  Created by Mikhail Korzh on 27.09.2026.
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

struct AboutView: View {
    var body: some View {
        VStack {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable().scaledToFit()
                .frame(width: 100)
            Text(Bundle.main.appName).font(.title)
            Text(Bundle.main.versionAndBuild)
                .textSelection(.enabled)
                .padding(.bottom)
            Text(Bundle.main.copiright)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Acknowledgements") {
                openAcknowledgements()
            }
                .padding()
        }
        .multilineTextAlignment(.center)
        .frame(width: 200, height: 250)
        .padding()
    }
    
    private func openAcknowledgements() {
        guard let url = Bundle.main.url(
            forResource: "Acknowledgements",
            withExtension: "pdf"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

#Preview {
    AboutView()
}
