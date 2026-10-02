//
//  Debug.swift
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
//  ---
//
//  Based on Debug.swift from CotEditor (https://coteditor.com)
//  Copyright © 2016-2024 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// A context-rich debug print utility with tangerine or lemon.
///
/// This function works similarly to `Swift.debugPrint()` but automatically enriches the output
/// with the current thread, file name, line number, and function name.
///
/// A 🍋 icon will be printed at the beginning of the message if it's invoked in a background thread, otherwise a 🍊.
///
/// - Parameters:
///   - items: Zero or more items to print.
///   - file: The name of the file where this function was called. Defaults to the current file.
///   - function: The name of the function where this was called. Defaults to the current function.
///   - line: The line number where this was called. Defaults to the current line.
nonisolated func harvest(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let icon = Thread.isMainThread ? "🍊" : "🍋"
    let fileName = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent

    if items.isEmpty {
        print("\(icon) \(fileName):\(line) \(function) ?")
    } else {
        print("\(icon) \(fileName):\(line) \(function) -> \(items.map({ "\($0)" }).formatted(.list(type: .and, width: .short)))")
    }
    #endif
}
