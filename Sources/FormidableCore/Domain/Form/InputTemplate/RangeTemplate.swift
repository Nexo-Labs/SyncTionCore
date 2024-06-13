//
//  RangeTemplate.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 30/11/22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

public struct Range: AbstractValue {
    public var start: Date? {
        didSet {
            if let start, let end, end < start {
                self.end = start
            } else {
                self.end = nil
            }
        }
    }

    public var end: Date? {
        didSet {
            guard let start else { return }
            if let end, start > end {
                self.start = end
            }
        }
    }

    public init(start: Date? = nil) {
        self.start = start
    }

    public init(start: Date? = nil, end: Date? = nil) {
        self.start = start
        self.end = end
    }

    public mutating func addEndDate() {
        let date = start
        end = date
    }
}

public struct RangeTemplate: InputTemplate {
    public let header: Header
    public var config: InputTemplateConfig
    public var value: Range
    public var isValid: Bool {
        !config.mandatory || (value.start != nil && value.end != nil)
    }

    public let addStart = FocusableId()
    #if os(macOS)
    public let inputStart = FocusableId(propagateKeys: [.left, .right, .up, .down, .enter], hints: InputFieldHints)
    public let inputEnd = FocusableId(propagateKeys: [.left, .right, .up, .down, .enter], hints: InputFieldHints)
    #else
    public let inputStart = FocusableId()
    public let inputEnd = FocusableId()
    #endif
    public let removeStart = FocusableId()
    public let addEnd = FocusableId()
    public let removeEnd = FocusableId()

    public var focusableInput: [FocusableId] {
        if value.start == nil {
            return [self.addStart]
        } else if value.end == nil {
            return [self.inputStart, self.removeStart, self.addEnd]
        } else {
            return [self.inputStart, self.removeStart, self.inputEnd, self.removeEnd]
        }
    }
    public var defaultFocusable: FocusableId? {
        value.start == nil ? self.addStart : self.removeStart
    }
    
    public init(
        header: Header,
        config: InputTemplateConfig = InputTemplateConfig(),
        value: Range = Range()
    ) {
        self.header = header
        self.config = config
        self.value = value
    }
    
    public var startDate: Date? {
        get {
            value.start
        }
        set(newValue) {
            guard let newValue else {
                value = Range()
                return
            }
            
            if value.start == nil {
                value = Range(start: newValue)
            } else {
                value.start = newValue
            }
        }
    }
    
    public var endDate: Date? {
        get {
            value.end
        }
        set(newValue) {
            guard let newValue else {
                if let start = value.start {
                    value = Range(start: start, end: newValue)
                } else {
                    value = Range()
                }
                return
            }
            
            if value.start == nil {
                return
            }
            value.end = newValue
        }
    }
    
    public mutating func actionate(inputHash: FocusableId?) -> FocusableId? {
        if inputHash == self.addStart {
            value = Range(start: Date.now)
            return self.inputStart
        } else if inputHash == self.addEnd {
            value.addEndDate()
            return self.inputEnd
        } else if inputHash == self.removeStart {
            value = Range()
            return self.addStart
        } else if inputHash == self.removeEnd {
            value.end = nil
            return self.addEnd
        }
        return inputHash
    }
    
    public enum CodingKeys: String, CodingKey {
        case header, config, value
    }
}
