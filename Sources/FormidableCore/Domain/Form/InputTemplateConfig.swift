//
//  InputTemplateConfig.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 12/2/23.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

public protocol AbstractTemplateConfig: Codable, Hashable, Sendable {
    var mandatory: Bool { get }
    var active: Bool { get set }
}

public struct InputTemplateConfig: AbstractTemplateConfig {
    @Editable public var mandatory: Bool
    @Editable public var active: Bool
    
    public init(
        mandatory: Editable<Bool> = Editable(false, constant: false),
        active: Editable<Bool> = Editable(true, constant: false)
    ) {
        self._active = active
        self._mandatory = mandatory
    }
}

@propertyWrapper
public struct Editable<Wrapped: Hashable & Sendable>: Hashable, Sendable {
    public let constant: Bool
    private var value: Wrapped
    public var wrappedValue: Wrapped {
        get {
            value
        }
        set {
            if constant { return }
            value = newValue
        }
    }

    public init(_ wrappedValue: Wrapped, constant: Bool) {
        self.value = wrappedValue
        self.constant = constant
    }
}

extension Editable: Codable where Wrapped: Codable {
    
}
extension Editable: Equatable where Wrapped: Equatable {
    
}
