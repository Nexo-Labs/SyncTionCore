//
//  InputTemplate.swift
//  SyncTion (macOS)
//
//  Created by rgarciah on 1/7/21.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import SwiftUI

public protocol AbstractValue: Codable, Hashable, Sendable {
}

public protocol InputTemplate: Codable, Identifiable, Hashable, Sendable {
    associatedtype Value: AbstractValue
    associatedtype Config: AbstractTemplateConfig
    
    var id: InputId { get }
    var header: Header { get }
    var config: Config { get set }
    var isValid: Bool { get }
    var value: Value { get set }
    
    var focusableInput: [FocusableId] { get }
    var defaultFocusable: FocusableId? { get }

    init(header: Header, config: Config, value: Value)
    mutating func actionate(inputHash: FocusableId?) -> FocusableId?
}

public struct Tag: Codable, Equatable, Hashable, Sendable {
    public init(rawValue: UUID? = nil) {
        self.rawValue = rawValue ?? UUID()
    }
    
    public var rawValue: UUID
    
    public typealias RawValue = UUID
        
    public init?(_ tag: String) {
        guard let rawValue = UUID(uuidString: tag) else { return nil }
        self.rawValue = rawValue
    }
}

public struct Header: Codable, Hashable, Sendable {
    public let id: InputId
    public let name: String
    public let icon: String
    public let tags: Set<Tag>
    
    public init(name: String, icon: String, tags: Set<Tag>) {
        self.id = InputId()
        self.name = name
        self.icon = icon
        self.tags = tags
    }
}

public extension InputTemplate {
    var id: InputId {
        header.id
    }

    var show: Bool {
        self.config.active || !self.isValid
    }

    var focusableInput: [FocusableId] {
        []
    }
    var defaultFocusable: FocusableId? {
        nil
    }
}

