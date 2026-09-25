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

@main
struct MarkApp: App {
    
    @FocusedValue(\.documentUIState)
    private var documentUIState
        
    var body: some Scene {
        DocumentGroup { document in
            DocumentView(document: document)
        } makeDocument: { configuration, context in
            MarkDocument()
        }
        .commands {
            CommandMenu("Tools") {
                Button("Speakers") {
                    documentUIState?.isSpeakerSheetPresented = true
                }
                .disabled(documentUIState == nil)
            }
        }
        
        /*
        Settings {
            SettingsView()
        }
         */
    }
}
