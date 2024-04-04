//
//  Form.swift
//  SyncTion (macOS)
//
//  Created by rgarciah on 27/6/21.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

public struct FormModel: Identifiable {
    public var id: FormId = FormId()
    public var template: FormTemplate
    public var inputs: InputTemplates

    public init(template: FormTemplate) {
        self.template = template
        inputs = template.inputs
    }

    public var availableSteps: [Step] {
        template.steps.filter { step in
            inputs.contains{
                $0.template.header.tags.contains(step.id) && $0.template.show
            }
        }
    }
        
    public var invalidInputs: [Header] {
        inputs.filter{ !$0.template.isValid }.map(\.template.header)
    }
        
    public func inputs(by step: Step?) -> InputTemplates {
        inputs.filter {
            guard !template.steps.isEmpty, let tag = step?.id else {
                return $0.template.show
            }
            return $0.template.header.tags.contains(tag) && $0.template.show
        }
    }
    
    public func input(by inputId: InputId) -> (any InputTemplate)? {
        inputs.first { $0.id == inputId }?.template
    }
    
    public func input(by focusedField: FocusableId) -> (any InputTemplate)? {
        inputs.first {
            $0.template.focusableInput.contains(focusedField)
        }?.template
    }
    
    public func input(by tag: Tag, all: Bool = false) ->  (any InputTemplate)? {
        inputs.first {
            ($0.template.show || all) && $0.template.header.tags.contains(tag)
        }?.template
    }
    
    public func step(by id: InputId) -> Step? {
        template.steps.first {
            inputs[id]?.template.header.tags.contains($0.id) ?? false
        }
    }
            
    @discardableResult public mutating func actionate(inputId: InputId, focusableId: FocusableId? = nil) -> FocusableId? {
        return inputs[inputId]?.template.actionate(inputHash: focusableId)
    }
    
    public mutating func saveValuesAsDefault() {
        template.inputs = inputs
    }
    
    public mutating func reload() {
        inputs = template.inputs
    }

    public var firstInputId: InputId? {
        if let firstInputId = template.firstInputId, inputs[firstInputId] != nil {
            return firstInputId
        } else {
            return inputs
                .filter{$0.template.show}
                .first?.id
        }
    }
        
    public func step(of input: any InputTemplate, old: Step?) -> Step? {
        let new = template.steps.first { input.header.tags.contains($0.id) }
        guard let old else {
            return availableSteps.first
        }
        return availableSteps.newStep(old: old, new: new)
    }
    
    public func nextStep(from: Tag?) -> Step? {
        availableSteps.next(
            of: {$0.id == from},
            overflow: true
        ) ?? availableSteps.first
    }
        
    private func step(for id: InputId) -> Step? {
        template.steps.first {
            inputs[id]?.template.header.tags.contains($0.id) ?? false
        }
    }
}

