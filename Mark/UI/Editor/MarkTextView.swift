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

final class MarkTextView: NSTextView {
    
    var onResize: (() -> Void)?
    var textWidth: CGFloat = DefaultSettings.editorTextWidth {
        didSet { needsLayout = true }
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        onResize?()
    }
    
    override var textContainerOrigin: NSPoint {
        guard let textContainer else { return super.textContainerOrigin }

        let containerWidth = textContainer.containerSize.width
        let availableWidth = bounds.width - textContainerInset.width * 2

        let offset = max(0, (availableWidth - containerWidth) / 2)

        return NSPoint(x: textContainerInset.width + offset, y: super.textContainerOrigin.y)
    }

    override func changeFont(_ sender: Any?) { }
    override func changeColor(_ sender: Any?) { }
}
