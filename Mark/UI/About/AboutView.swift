//
//  AboutView.swift
//  Mark
//
//  Created by Mikhail Korzh on 10.09.2026.
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
        VStack(alignment: .leading) {
            Text("Mark")
                .font(.largeTitle)
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.caption)
                .textSelection(.enabled)
                .padding(.bottom, 12)
            Text("Copyright © \(String(currentYear)) Mikhail Korzh.\nMark is licensed under \(Text("[GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)").underline()). Source code is available on \(Text("[GitHub](https://github.com/elupit/mark)").underline()).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .tint(.secondary)
        }
        .padding()
    }

    // MARK: - Private

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0.0"
    }

    private var buildNumber: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "0"
    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
}

#Preview {
    AboutView()
        .frame(width: 250, height: 300)
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
}
