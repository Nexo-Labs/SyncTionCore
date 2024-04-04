//
//  DateTemplate.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 31/12/22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

public struct DateValue: AbstractValue {
    public var date: Date?
    
    public init(date: Date? = nil) {
        self.date = date
    }
}

#if os(macOS)
public let InputFieldHints = [
    ShortcutHint(key: .up, description: String(localized: "Up/down datetime")),
    ShortcutHint(key: .space, description: String(localized: "Set a calendars date")),
    ShortcutHint(key: .enter, description: String(localized: "Open/close calendar"))
]
#endif

public struct DateTemplate: InputTemplate {
    public let header: Header
    public var config: InputTemplateConfig
    public var value: DateValue
    public let isValid: Bool = true
    
    public let addField = FocusableId()
    #if os(macOS)
    public let inputField = FocusableId(propagateKeys: [.left, .right, .up, .down, .enter], hints: InputFieldHints)
    #else
    public let inputField = FocusableId()
    #endif
    public let removeField = FocusableId()
    
    public var focusableInput: [FocusableId] {
        if value.date == nil {
            return [addField]
        } else {
            return [inputField, removeField]
        }
    }

    public var defaultFocusable: FocusableId? {
        value.date == nil ? addField : removeField
    }
    public init(
        header: Header,
        config: InputTemplateConfig = InputTemplateConfig(),
        value: DateValue = DateValue()
    ) {
        self.header = header
        self.config = config
        self.value = value
    }
    
    public mutating func actionate(inputHash: FocusableId?) -> FocusableId? {
        if inputHash == addField {
            value.date = Date.now
            return inputField
        } else if inputHash == removeField {
            value.date = nil
            return addField
        }
        return inputHash
    }

    public enum CodingKeys: String, CodingKey {
        case header, config, value
    }
}
