//
//  FontPicker.swift
//  Mark
//
//  Created by Mikhail Korzh on 03.10.2026.
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

final class FontPicker: NSObject {

    var onSelect: ((String) -> Void)?
    var onUnsupportedFont: ((String) -> Void)?

    func show(currentFontName: String, size: Double) {
        let font: NSFont

        if currentFontName == DefaultSettings.editorFontName {
            font = NSFont.systemFont(ofSize: size)
        } else {
            font = NSFontManager.shared.font(
                withFamily: currentFontName,
                traits: [],
                weight: 5,
                size: size
            ) ?? NSFont.systemFont(ofSize: size)
        }

        NSFontManager.shared.target = self
        NSFontManager.shared.setSelectedFont(font, isMultiple: false)
        NSFontManager.shared.orderFrontFontPanel(nil)
    }

    @objc func changeFont(_ sender: NSFontManager) {
        let font = sender.convert(sender.selectedFont ?? NSFont.systemFont(ofSize: 13))

        guard let family = font.familyName else { return }

        if supportsRegularAndBold(family) {
            onSelect?(family)
        } else {
            onUnsupportedFont?(family)
        }
    }

    private func supportsRegularAndBold(_ family: String) -> Bool {
        guard let members = NSFontManager.shared.availableMembers(
            ofFontFamily: family
        ) else { return false }

        var hasRegular = false
        var hasBold = false

        for member in members {
            guard let traits = member[3] as? NSNumber else { continue }

            let mask = NSFontTraitMask(rawValue: traits.uintValue)

            if mask.contains(.boldFontMask) {
                hasBold = true
            } else {
                hasRegular = true
            }
        }

        return hasRegular && hasBold
    }
}
