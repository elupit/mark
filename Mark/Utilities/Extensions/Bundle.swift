//
//  Bundle.swift
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
//  Based on Bundle+AppInfo.swift from CotEditor (https://coteditor.com)
//  Copyright © 2018-2026 1024jp
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

extension Bundle {
    /// The human-friendly version expression (semantic versioning).
    final var version: String? {
        self.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    /// The build number.
    final var build: String? {
        self.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }
    
    /// The human-friendly version and build expression.
    final var versionAndBuild: String {
        String("Version \(version ?? "0.0.0") (\(build ?? "0"))")
    }
    
    /// The human-friendly copyright notice and license information for the application.
    final var copiright: String {
        let year = String(Calendar.current.component(.year, from: Date()))
        return String("Copyright © \(year) Mikhail Korzh.\nReleased under GNU GPL v3.")
    }
    
    /// The name of the App.
    final var appName: String {
        String("Mark")
    }
}
