//
//  BoolTemplate.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 4/11/22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

extension Bool: AbstractValue {
}

public struct BoolTemplate: InputTemplate {
    public let header: Header
    public var config: InputTemplateConfig
    public var value: Bool
    public let isValid: Bool = true
    
    public let toggleInput = FocusableId()
    public var focusableInput: [FocusableId] {
        [toggleInput]
    }
    public var defaultFocusable: FocusableId? {
        toggleInput
    }

    public init(
        header: Header,
        config: InputTemplateConfig = InputTemplateConfig(),
        value: Bool = false
    ) {
        self.header = header
        self.config = config
        self.value = value
    }
    
    public mutating func actionate(inputHash: FocusableId?) -> FocusableId? {
        if toggleInput == inputHash {
            value.toggle()
        }
        return inputHash
    }
    
    public enum CodingKeys: String, CodingKey {
        case header, config, value
    }
}
