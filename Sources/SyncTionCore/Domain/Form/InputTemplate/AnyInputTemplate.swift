//
//  AnyInputTemplate.swift
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

public struct AnyInputTemplate: Codable, Hashable, Identifiable {
    public var id: InputId {
        template.id
    }
    
    public var template: any InputTemplate {
        get {
            if let options = options {
                return options
            } else if let text = text {
                return text
            } else if let number = number {
                return number
            } else if let range = range {
                return range
            } else if let date = date {
                return date
            } else if let bool = bool {
                return bool
            } else {
                fatalError("")
            }
        }
        set {
            self = Self(newValue)
        }
    }

    public init(_ template: some InputTemplate) {
        if let template = template as? OptionsTemplate {
            options = template
        } else if let template = template as? TextTemplate {
            text = template
        } else if let template = template as? NumberTemplate {
            number = template
        } else if let template = template as? RangeTemplate {
            range = template
        } else if let template = template as? DateTemplate {
            date = template
        } else if let template = template as? BoolTemplate {
            bool = template
        }
    }

    public var options: OptionsTemplate?
    public var text: TextTemplate?
    public var number: NumberTemplate?
    public var range: RangeTemplate?
    public var date: DateTemplate?
    public var bool: BoolTemplate?
}

