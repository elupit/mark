//
//  TextEditorView.swift
//  Mark
//
//  Created by Mikhail Korzh on 23.09.2026.
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

struct TextEditorView: NSViewRepresentable {
    
    let document: MarkDocument
    let store: ParsedDocumentStore
    let editorState: EditorState
    
    let fontName: String
    let fontSize: Double
    let lineSpacing: Double
    let paragraphSpacing: Double
    let textWidth: Double
    let justifyText: Bool
    let interviewerBold: Bool
    
    let textInsets = NSSize(width: 84, height: 84) // Margins: 6 * default fontSize
        
    typealias NSViewType = NSScrollView
    
    func makeCoordinator() -> EditorController {
        let controller = EditorController(
            document: document,
            parsedDocumentStore: store
        )
        editorState.attach(controller)
        return controller
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        
        let scrollView = NSScrollView()

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        let textView = MarkTextView()
        
        textView.isEditable = !document.meta.isLocked
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.textContainerInset = textInsets
        
        context.coordinator.configure(
            textView,
            fontName: fontName,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            paragraphSpacing: paragraphSpacing,
            textWidth: textWidth,
            justifyText: justifyText,
            interviewerBold: interviewerBold
        )
        textView.delegate = context.coordinator
        
        scrollView.documentView = textView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView
        else { return }
        
        textView.isEditable = !document.meta.isLocked
        
        context.coordinator.updateSettingsIfNeeded(
            fontName: fontName,
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            paragraphSpacing: paragraphSpacing,
            textWidth: textWidth,
            justifyText: justifyText,
            interviewerBold:
                interviewerBold
        )
        
        context.coordinator.updateTextIfNeeded(
            document.text,
            in: textView
        )
    }
}
