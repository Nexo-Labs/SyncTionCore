//
//  Identity.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 11/1/23.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation


public protocol Identity: Hashable, Codable, Equatable, Sendable {
    var hash: UUID { get }
}

public extension Identity {
    var uuidString: String {
        hash.uuidString
    }
}

public struct FormId: Identity {
    public let hash: UUID
    
    init() {
        self.hash = UUID()
    }
}

public struct InputId: Identity {
    public let hash: UUID

    public init(_ hash: UUID? = nil) {
        self.hash = hash ?? UUID()
    }
}

public struct FocusableId: Identity {
    public let hash: UUID
#if os(macOS)
    public let propagateKeys: [EventShortcut]
    public var hints: [ShortcutHint] = []
#endif
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
    
    public static func == (lhs: FocusableId, rhs: FocusableId) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    
#if os(macOS)
    public init(
        _ hash: UUID? = nil,
        propagateKeys: [KeyboardShortcuts.Shortcut] = [],
        hints: [ShortcutHint] = []
    ) {
        self.hash = hash ?? UUID()
        self.propagateKeys = propagateKeys
        self.hints = hints
    }
#else
    public init(_ hash: UUID? = nil) {
        self.hash = hash ?? UUID()
    }
#endif
}

public protocol FocusableIdProtocol: Identity {
    var focusableId: FocusableId { get }
}

public extension FocusableIdProtocol {
    var focusableId: FocusableId {
        FocusableId(hash)
    }
}

#if os(macOS)

public struct ShortcutHint: Codable, Equatable, Identifiable, Sendable {
    public var id: EventShortcut {
        key
    }
    
    public let key: EventShortcut
    public let description: String
    
    public init(key: EventShortcut, description: String) {
        self.key = key
        self.description = description
    }
}

public extension KeyboardShortcuts.Shortcut {
    static let space = EventShortcut(.space)
    static let escape = EventShortcut(.escape)
    static let enter = EventShortcut(.`return`)
    static let shiftEnter = EventShortcut(.`return`, modifiers: [.shift])
    static let tab = EventShortcut(.tab)
    static let shiftTab = EventShortcut(.tab, modifiers: [.shift])
    static let left = EventShortcut(.leftArrow)
    static let right = EventShortcut(.rightArrow)
    static let up = EventShortcut(.upArrow)
    static let down = EventShortcut(.downArrow)
    
    var icons: [String] {
        return modifiers.icons + [key?.icon ?? ""]
    }
}
#endif
