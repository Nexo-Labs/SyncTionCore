//
//  TextTemplate.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 9/12/22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

extension String: AbstractValue {
}

public struct TextTemplate: InputTemplate {
    public let header: Header
    public var config: InputTemplateConfig
    public var value: String
    public let isValid: Bool = true

    #if os(macOS)
    public let inputField = FocusableId(propagateKeys: [.left, .right])
    #else
    public let inputField = FocusableId()
    #endif

    public var focusableInput: [FocusableId] {
        [inputField]
    }
    public var defaultFocusable: FocusableId? {
        inputField
    }

    public init(
        header: Header,
        config: InputTemplateConfig = InputTemplateConfig(),
        value: String = ""
    ) {
        self.header = header
        self.config = config
        self.value = value
    }

    public mutating func actionate(inputHash: FocusableId?) -> FocusableId? {
        if inputHash == self.inputField {
            return nil
        }
        return inputHash
    }
    
    public enum CodingKeys: String, CodingKey {
        case header, config, value
    }
}
