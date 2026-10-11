//
//  MarkTextView.swift
//  Mark
//
//  Created by Mikhail Korzh on 26.09.2026.
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

import AppKit
import SwiftUI

final class MarkTextView: NSTextView {
    
    var editorController: EditorController?
    var onResize: (() -> Void)?
    var textWidth: CGFloat = DefaultSettings.editorTextWidth {
        didSet { needsLayout = true }
    }
    
    private var highlightRangeToRemove: NSRange?
    private var commentPopover: NSPopover?
    private var commentPopoverRange: NSRange?

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        onResize?()
        repositionCommentPopover()
    }
    
    override var textContainerOrigin: NSPoint {
        guard let textContainer else { return super.textContainerOrigin }

        let containerWidth = textContainer.containerSize.width
        let availableWidth = bounds.width - textContainerInset.width * 2

        let offset = max(0, (availableWidth - containerWidth) / 2)

        return NSPoint(x: textContainerInset.width + offset, y: super.textContainerOrigin.y)
    }
    
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            let point = convert(event.locationInWindow, from: nil)

            if let index = characterIndex(at: point) {
                let selection = NSRange(location: index, length: 0)

                if let range = editorController?.highlightRange(containing: selection),
                   let highlight = editorController?.highlight(at: selection),
                   !(highlight.comment?.isEmpty ?? true) {
                    showCommentPopover(for: range)
                    return
                }
            }
        }

        super.mouseDown(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        guard let menu = super.menu(for: event) else { return nil }
        let selection = selectedRange()
        
        // Remove unwanted items
        menu.items.removeAll {
            $0.action == NSSelectorFromString("_searchWithGoogleFromMenu:") ||
            $0.action == NSSelectorFromString("_performStandardShareMenuItem:")
        }
        
        menu.items.removeAll {
            guard let submenu = $0.submenu else { return false }
            return submenu.items.contains {
                $0.action == NSSelectorFromString("orderFrontFontPanel:") ||
                $0.action == NSSelectorFromString("orderFrontColorPanel:")
            }
        }
        
        menu.items.removeAll { $0.identifier == NSUserInterfaceItemIdentifier("removeHighlight") }
        
        // Add Highlight section before Cut
        if let range = editorController?.highlightRange(containing: selection) {
            let highlight = editorController?.highlight(at: selection)
            
            
            highlightRangeToRemove = range
            
            if let cutIndex = menu.items.firstIndex(where: {
                $0.action == #selector(NSText.cut(_:))
            }) {
                var index = cutIndex

                let hasComment = !(highlight?.comment?.isEmpty ?? true)

                if hasComment {
                    let removeItem = NSMenuItem(
                        title: "Remove",
                        action: nil,
                        keyEquivalent: ""
                    )

                    let submenu = NSMenu()

                    let removeCommentItem = NSMenuItem(
                        title: "Remove Comment",
                        action: #selector(removeComment(_:)),
                        keyEquivalent: ""
                    )
                    removeCommentItem.target = self

                    let removeHighlightItem = NSMenuItem(
                        title: "Remove Highlight & Comment",
                        action: #selector(removeHighlightAndComment(_:)),
                        keyEquivalent: ""
                    )
                    removeHighlightItem.target = self

                    submenu.addItem(removeCommentItem)
                    submenu.addItem(removeHighlightItem)
                    removeItem.submenu = submenu
                    removeItem.identifier = NSUserInterfaceItemIdentifier("removeHighlight")

                    menu.insertItem(removeItem, at: index)
                } else {
                    let removeItem = NSMenuItem(
                        title: "Remove Highlight",
                        action: #selector(removeHighlightAndComment(_:)),
                        keyEquivalent: ""
                    )
                    removeItem.target = self
                    removeItem.identifier = NSUserInterfaceItemIdentifier("removeHighlight")

                    menu.insertItem(removeItem, at: index)
                }

                index += 1

                if selection.length > 0 || highlight != nil {
                    let commentItem = NSMenuItem(
                        title: hasComment ? "Edit Comment" : "Add Comment",
                        action: #selector(addComment(_:)),
                        keyEquivalent: ""
                    )
                    commentItem.target = self

                    menu.insertItem(commentItem, at: index)
                    index += 1
                }

                menu.insertItem(.separator(), at: index)
            }
        } else {
            highlightRangeToRemove = nil
        }

        return menu
    }

    override func changeFont(_ sender: Any?) { }
    override func changeColor(_ sender: Any?) { }
    
    @objc func addComment(_ sender: Any?) {
        guard let range = editorController?.addComment() else { return }
        showCommentPopover(for: range)
    }
    
    @objc private func removeHighlight(_ sender: Any?) {
        guard let range = highlightRangeToRemove else { return }
        editorController?.removeHighlight(at: range)
    }
    
    @objc private func removeComment(_ sender: Any?) {
        guard let range = highlightRangeToRemove else { return }

        editorController?.updateHighlightComment(at: range, comment: "")
    }

    @objc private func removeHighlightAndComment(_ sender: Any?) {
        guard let range = highlightRangeToRemove else { return }

        editorController?.removeHighlight(at: range)
    }
}

private extension MarkTextView {
    func showCommentPopover(for range: NSRange) {
        commentPopoverRange = range

        let popover = NSPopover()
        let comment = editorController?.highlightComment(at: range) ?? ""

        popover.contentViewController = NSHostingController(
            rootView: CommentView(comment: comment) { [weak self] value in
                self?.editorController?.updateHighlightComment(
                    at: range,
                    comment: value
                )
                popover.close()
            }
        )

        popover.behavior = .semitransient
        commentPopover = popover

        guard let rect = rect(for: range) else { return }

        popover.show(relativeTo: rect, of: self, preferredEdge: .maxY)
    }
    
    func characterIndex(at point: NSPoint) -> Int? {
        guard let layoutManager, let textContainer else { return nil }

        let containerPoint = NSPoint(
            x: point.x - textContainerOrigin.x,
            y: point.y - textContainerOrigin.y
        )

        let index = layoutManager.characterIndex(
            for: containerPoint,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        return index < (string as NSString).length ? index : nil
    }
    
    private func rect(for range: NSRange) -> NSRect? {
        guard let layoutManager, let textContainer else { return nil }

        layoutManager.ensureLayout(for: textContainer)

        let glyphRange = layoutManager.glyphRange(
            forCharacterRange: range,
            actualCharacterRange: nil
        )

        return layoutManager.boundingRect(
            forGlyphRange: glyphRange,
            in: textContainer
        )
        .offsetBy(
            dx: textContainerOrigin.x,
            dy: textContainerOrigin.y
        )
    }
    
    private func repositionCommentPopover() {
        guard
            let popover = commentPopover,
            popover.isShown,
            let range = commentPopoverRange,
            let rect = rect(for: range)
        else { return }

        popover.positioningRect = rect
    }
}
