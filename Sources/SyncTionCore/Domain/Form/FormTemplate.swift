//
//  FormTemplate.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 10/10/22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

public struct FormTemplateId: FocusableIdProtocol {
    public let hash: UUID
    
    public init(_ hash: UUID? = nil) {
        self.hash = hash ?? UUID()
    }
}

public struct FormHeader: Identifiable, Codable, Hashable, Sendable {
    public var id: FormTemplateId
    public var style: FormModel.Style = .init(formName: "", color: "FFFFFF")
    public var lastOpen: Date?
    public var config: FormConfig
    public var integration: FormServiceId
    
    public init(id: FormTemplateId, style: FormModel.Style, lastOpen: Date? = nil, integration: FormServiceId) {
        self.id = id
        self.style = style
        self.lastOpen = lastOpen
        self.integration = integration
        self.config = FormConfig()
    }

    public static func preview(_ text: String, color: String, icon: FormIcon? = nil, theme: FormTheme? = nil, buttonStyle: FormModel.FormButtonStyle? = nil) -> FormHeader {
        FormHeader(
            id: .init(),
            style: .init(formName: text, icon: icon, color: color, theme: theme, buttonStyle: buttonStyle),
            integration: .init(hash: .init())
        )
    }
}

public struct FormConfig: Codable, Hashable, Sendable {
    public var recordingMode = RecordingMode.disabled
    
    public enum RecordingMode: Codable, Hashable, Sendable {
        case disabled
        case recordInput(InputId)
        case recordAndSend(InputId)
    }
}

public struct Step: Codable, Hashable {
    public let id: Tag
    public let name: String
    public var description: String? = nil
    public var direction: Direction = .Start
    public var isLast: Bool = false
    
    public init(
        id: Tag,
        name: String,
        description: String? = nil,
        direction: Direction = .Start,
        isLast: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.direction = direction
        self.isLast = isLast
    }
    
}

public extension Array where Element == Step {
    func newStep(old: Step, new: Step?) -> Step? {
        guard old != new else { return old }
        let direction = Direction(old: old.id, new: new?.id, steps: self.map(\.id))
        var new = new
        new?.direction = direction
        return new
    }
}

public enum Direction: Codable {
    case Back
    case Forward
    case Start
    
    public init(old: Tag, new: Tag?, steps: [Tag]) {
        let indexOld = steps.firstIndex{ $0 == old} ?? -1
        let indexCurrent = steps.firstIndex{ $0 == new} ?? -1
        self = indexOld > indexCurrent ? .Back : .Forward
    }
}

#if canImport(SwiftUI)
import SwiftUI
public extension Direction {
    var transition: AnyTransition {
        if case .Forward = self {
            return .move(edge: .trailing)
        } else {
            return .move(edge: .leading)
        }
    }
}
#endif

public struct FormTemplate: Identifiable, Codable, Hashable {
    public var header: FormHeader
    public var id: FormTemplateId {
        self.header.id
    }
    public var inputs: InputTemplates
    public var entrypointInputId: InputId? = nil
    public var steps: [Step]
    
    public init(_ header: FormHeader, inputs: [any InputTemplate], steps: [Step] = [], entrypointInputId: InputId? = nil) {
        self.header = header
        self.inputs = inputs.compactMap{ AnyInputTemplate($0) }
        self.steps = steps
        self.entrypointInputId = entrypointInputId
    }
    
    public mutating func move(from source: IndexSet, to destination: Int) {
        inputs.move(fromOffsets: source, toOffset: destination)
    }
}

public typealias FormName = String
public typealias AuthId = UUID

public enum FormTheme: String, Codable, Hashable, Sendable {
    case Neumorphism = "Neumorphism"
    case Bordered = "Bordered"
    case PlainGrey = "PlainGrey"
    
    public static let all: [Self] = [.Bordered, .Neumorphism, .PlainGrey]
}



public extension FormModel {
    struct FormButtonStyle: Codable, Hashable, Sendable {
        public var inverted = false
        public var big = false
        public var hideText = false
        public var hideIcon = false

        public init(inverted: Bool = false, big: Bool = false, hideText: Bool = false, hideIcon: Bool = false) {
            self.inverted = inverted
            self.big = big
            self.hideText = hideText
            self.hideIcon = hideIcon
        }
    }

    struct Style: Codable, Hashable, Sendable {
        public var formName: FormName
        public var icon: FormIcon = .sfsymbols("square.and.pencil", nil)
        public var color: String
        public var theme: FormTheme = .Bordered
        public var buttonStyle = FormButtonStyle()
        
        public init(formName: FormName, icon: FormIcon? = nil, color: String, theme: FormTheme? = nil, buttonStyle: FormButtonStyle? = nil) {
            self.formName = formName
            self.icon = icon ?? .sfsymbols("square.and.pencil", nil)
            self.color = color
            self.theme = theme ?? .Bordered
            self.buttonStyle = buttonStyle ?? self.buttonStyle
        }
    }
}

public enum FormIcon: Codable, Hashable, Sendable {
    case sfsymbols(String, String?)
    case data(UUID)
    case `static`(String, loadAsPng: Bool)
    
    public var string: String {
        switch self {
        case let .static(str, _):
            return str
        case let .data(uuid):
            return uuid.uuidString
        case let .sfsymbols(str, _):
            return str
        }
    }
    
    public var isStatic: Bool {
        if case .static(_, _) = self {
            return true
        }
        return false
    }
    
    public var loadAsPng: Self {
        if case let .static(str, _) = self {
            return .static(str, loadAsPng: true)
        }
        return self
    }
}
