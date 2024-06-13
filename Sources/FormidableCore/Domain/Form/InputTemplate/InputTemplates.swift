//
//  InputTemplates.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 10/12/22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

public typealias InputTemplates = [AnyInputTemplate]

public extension Array where Self == InputTemplates {
    mutating func append(template: AnyInputTemplate) {
        let index = firstIndex {
            $0.id == template.id
        }

        if let index {
            self[index] = template
        } else {
            append(template)
        }
    }
        
    subscript(key: InputId) -> Element? {
        get {
            first {
                $0.id == key
            }
        }
        set {
            let index = firstIndex(where: {
                $0.id == key
            })

            if let index, let newValue {
                self[index] = newValue
            } else {
                if let newValue {
                    append(newValue)
                }
            }
        }
    }

    mutating func edit<Template:InputTemplate>(_ tag: Tag, type: Template.Type, edit: (inout Template) -> Void) {
        self = map {
            guard $0.template.header.tags.contains(tag), var input = $0.template as? Template else {
                return $0
            }
            edit(&input)
            return AnyInputTemplate(input)
        }
    }

    mutating func edit<Template:InputTemplate>(_ id: InputId, type: Template.Type, edit: (inout Template) -> Void) {
        self = map {
            guard $0.template.header.id == id, var input = $0.template as? Template else {
                return $0
            }
            edit(&input)
            return AnyInputTemplate(input)
        }
    }

    func first<I: InputTemplate>(tag: Tag) -> I? {
        first {
            $0.template.header.tags.contains(tag)
        }?.template as? I
    }

    func filter<I: InputTemplate>(tag: Tag) -> [I]? {
        filter {
            $0.template.header.tags.contains(tag)
        } as? [I]
    }
}
