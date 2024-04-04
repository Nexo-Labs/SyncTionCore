//
//  FormKeyListener.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 1/11/22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#if os(macOS)
import AppKit

public extension KeyboardShortcuts {
    private static var cacheFormTemplateIds: Set<FormTemplateId> = []

    static func register(formIds: [FormTemplateId], onKeyDown: @escaping (FormTemplateId) -> Void) {
        KeyboardShortcuts.isPaused = false
        formIds.forEach { id in
            guard !cacheFormTemplateIds.contains(id) else { return }
            cacheFormTemplateIds.insert(id)
            KeyboardShortcuts.onKeyDown(for: KeyboardShortcuts.Name.loadForm(id)) {
                onKeyDown(id)
            }
        }
        cacheFormTemplateIds.forEach {
            guard !formIds.contains($0) else { return }
            cacheFormTemplateIds.remove($0)
            KeyboardShortcuts.disable(KeyboardShortcuts.Name.loadForm($0))
        }
    }
}

public extension KeyboardShortcuts.Name {
    static let lastForm = Self("LAST_FORM")
    static let loadSelector = Self("LOAD_SELECTOR")
    static let loadForm: (FormTemplateId) -> Self = {
        KeyboardShortcuts.Name("LOAD_FORM_\($0.hash.uuidString)")
    }
}

public extension NSEvent.ModifierFlags {
    var icons: [String] {
        var icons: [String] = []
        if contains(.control) { icons.append("control") }
        if contains(.option) { icons.append("option") }
        if contains(.shift) { icons.append("shift") }
        if contains(.command) { icons.append("command") }
        if contains(.function) { icons.append("fn") }
        return icons
    }
}
#endif
