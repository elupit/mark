//
//  MarkApp.swift
//  Mark
//
//  Created by Mikhail Korzh on 07.09.2026.
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

@main
struct MarkApp: App {
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        DocumentGroup(newDocument: Document()) { file in
            EditorView(document: file.$document)
        }
        
        Window("About Mark", id: "about") {
            AboutView()
                .frame(width: 250, height: 300)
                .toolbar(removing: .title)
                .toolbarBackground(.hidden, for: .windowToolbar)
                .windowMinimizeBehavior(.disabled)
        }
        .windowResizability(.contentSize)

        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Mark") {
                    openWindow(id: "about")
                }
            }
        }
    }
}
