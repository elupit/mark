//
//  DefaultSettings.swift
//  Mark
//
//  Created by Mikhail Korzh on 02.10.2026.
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

enum DefaultSettings {
    
    // Editor
    static let editorFontName = "System"
    static let editorFontSize = 14.0
    static let editorLineSpacing = 1.2
    static let editorParagraphSpacing = 1.0
    static let editorTextWidth = 600.0
    static let editorJustifyText = false
    static let editorInterviewerBold = true
    
    static let defaults: [String: Any] = [
        // Editor
        DefaultKeys.Editor.fontName: editorFontName,
        DefaultKeys.Editor.fontSize: editorFontSize,
        DefaultKeys.Editor.lineSpacing: editorLineSpacing,
        DefaultKeys.Editor.paragraphSpacing: editorParagraphSpacing,
        DefaultKeys.Editor.justifyText: editorJustifyText,
        DefaultKeys.Editor.textWidth: editorTextWidth,
        DefaultKeys.Editor.interviewerBold: editorInterviewerBold
    ]
    
    
}
