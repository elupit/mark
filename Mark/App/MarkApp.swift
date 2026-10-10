//
//  MarkApp.swift
//  Mark
//
//  Created by Mikhail Korzh on 20.09.2026.
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

@main struct MarkApp: App {
    
    @FocusedValue(\.documentUIState) private var documentUIState
    @Environment(\.openWindow) private var openWindow
    
    init() {
        // Register default settings
        UserDefaults.standard.register(
            defaults: DefaultSettings.defaults
        )
    }
        
    var body: some Scene {
        DocumentGroup { document in
            DocumentView(document: document)
                .frame(minWidth: 500, minHeight: 200)
        } makeDocument: { configuration, context in
            MarkDocument()
        }
            
        // Commands
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button { openWindow(id: "about") }
                label: { Text("About Mark") }
            }
    
            CommandGroup(after: .importExport) {
                
                Button("Export as Plain Text…") { documentUIState?.export?() }
                .disabled(documentUIState == nil)
                
                Divider()
                
                Button { documentUIState?.toggleLock?() }
                label: { Label(
                    documentUIState?.isLocked == true ? "Unlock Document" : "Lock Document",
                    systemImage: documentUIState?.isLocked == true ? "lock.open" : "lock"
                ) }
                .labelStyle(.titleAndIcon)
                .disabled(documentUIState == nil)
            }
            
            CommandMenu("Format") {
                Button { documentUIState?.highlight?() }
                label: { Label("Highlight", systemImage: "highlighter") }
                .labelStyle(.titleAndIcon)
                .disabled(documentUIState == nil)
                .keyboardShortcut("h", modifiers: [.shift, .command])
            }

            
            CommandMenu("Interview") {
                Button { documentUIState?.isSpeakerSheetPresented = true }
                label: { Label("Speakers", systemImage: "person.2") }
                .labelStyle(.titleAndIcon)
                .disabled(documentUIState == nil)
            }
        }
        
        Window("About Mark", id: "about") {
            AboutView()
                .toolbar(removing: .title)
                .toolbarBackground(.hidden, for: .windowToolbar)
                .windowMinimizeBehavior(.disabled)
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        
        
        Settings {
            SettingsView()
        }
    }
}
