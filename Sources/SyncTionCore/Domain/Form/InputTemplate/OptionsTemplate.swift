//
//  OptionsTemplate.swift
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

public struct Options: AbstractValue {
    public var singleSelection: Bool = false

    public var options: [Option] {
        didSet {
            let oldSelectedIds = Set(oldValue.filter(\.selected).map(\.optionId))
            let currentSelectedIds = Set(options.filter(\.selected).map(\.optionId))
            let removeIds = oldSelectedIds.intersection(currentSelectedIds)
            
            if singleSelection, currentSelectedIds.count > 1 {
                options = options.map {
                    var opt = $0
                    if removeIds.contains(opt.optionId) {
                        opt.selected = false
                    }
                    return opt
                }
            }
        }
    }
    
    public var unhidden: [Option] {
        options.filter {
            !$0.hidden || $0.selected
        }
    }
    public var selected: [Option] {
        options.filter(\.selected)
    }
    
    public init(options: [Option] = [], singleSelection: Bool = true) {
        self.options = options
        self.singleSelection = singleSelection
    }
    
    public mutating func filterOptions(byText text: String) {
        let text = text.lowercased()
        self.options = options.reduce(into: []) { result, option in
            var filteredOption = option
            filteredOption.hidden = text.isEmpty ? false : !option.description.lowercased().contains(text)
            filteredOption.hidden = filteredOption.hidden && !filteredOption.selected
            result.append(filteredOption)
        }
    }
    
    public mutating func load(options: [Option], keepSelected: Bool) {
        let newIds = options.map(\.optionId)
        var selected = selected
        if !keepSelected {
            selected = selected.filter {
                newIds.contains($0.optionId)
            }
        }
        
        var options = selected + options
        options = options
            .removeDuplicates()
        self.options = options
    }
    
    public mutating func toggle(_ optionId: OptionId) {
        options = options.map {
            var option = $0
            if option.id == optionId {
                option.selected.toggle()
            }
            return option
        }
    }
    
    public mutating func clean() {
        options = options.filter(\.selected)
    }
}

public struct OptionId: FocusableIdProtocol {
    public let hash: UUID
    
    public init(_ id: UUID? = nil) {
        self.hash = id ?? UUID()
    }
}

public typealias OptionIcon = FormIcon

public struct Option: Codable, Hashable, Identifiable, Sendable {
    public let id: OptionId
    public let optionId: String
    public let icon: OptionIcon?
    public let description: String
    public var selected: Bool
    public var hidden: Bool = false
    public var smallerDescription: String? {
        description.count > 25 ? "\(String(description.prefix(25)))..." : description
    }
    
    public init(optionId: String, icon: OptionIcon? = nil, description: String, selected: Bool = false) {
        id = OptionId()
        self.icon = icon
        self.optionId = optionId
        self.description = description
        self.selected = selected
    }
}

public extension [Option] {
    func removeDuplicates() -> [Option] {
        var unique = [Option]()
        for option in self {
            if !unique.contains(where: { $0.optionId == option.optionId }) {
                unique.append(option)
                continue
            } else {
                if option.selected {
                    unique.removeAll {
                        $0.optionId == option.optionId
                    }
                    unique.append(option)
                }
            }
        }
        return unique
    }
}

public struct OptionsTemplate: InputTemplate {
    public let header: Header
    public var config: OptionsTemplateConfig
    public var value: Options
    public var search: String = ""

    public var isValid: Bool {
        guard self.config.mandatory else { return true }
        return !value.selected.isEmpty
    }

    public let searchField = FocusableId()
    public var focusableInput: [FocusableId] {
        let optionIds = value.unhidden.map(\.id.focusableId)
        return optionIds.isEmpty ? [searchField] : optionIds
    }
    public var defaultFocusable: FocusableId? {
        value.selected.first?.id.focusableId ?? focusableInput.first ?? searchField
    }
    
    public init(
        header: Header,
        config: OptionsTemplateConfig,
        value: Options = Options()
    ) {
        self.header = header
        self.config = config
        self.value = value
        self.value.singleSelection = config.singleSelection
    }
    
    public mutating func actionate(inputHash: FocusableId?) -> FocusableId? {
        if let inputHash {
            value.toggle(OptionId(inputHash.hash))
        }
        return inputHash
    }
    
    public mutating func load(
        options: [Option],
        keepSelected: Bool,
        sorting: [(Option, Option) -> Bool] = [defaultSorting]
    ) {
        self.value.load(options: options, keepSelected: keepSelected)
        sorting.forEach { sorting in
            self.value.options.sort(by: sorting)
        }
    }
    
    public static let defaultSorting: (Option, Option) -> Bool = {
        $0.description < $1.description
    }
    
    public enum CodingKeys: String, CodingKey {
        case header, config, value
    }
}

public struct OptionsTemplateConfig: AbstractTemplateConfig {
    @Editable public var mandatory: Bool
    @Editable public var active: Bool
    @Editable public var singleSelection: Bool
    @Editable public var hideDescription: Bool
    @Editable public var typingSearch: Bool
    //TODO: Esto no debería estar hardcodeado aquí, construir un sistema de almacenamiento de constantes
    public var targetId: String?
    
    public init(
        active: Editable<Bool> = Editable(true, constant: false),
        mandatory: Editable<Bool> = Editable(false, constant: false),
        singleSelection: Editable<Bool>,
        typingSearch: Editable<Bool> = Editable(false, constant: false),
        hideDescription: Editable<Bool> = Editable(false, constant: false),
        targetId: String? = ""
    ) {
        self._singleSelection = singleSelection
        self._typingSearch = typingSearch
        self._hideDescription = hideDescription
        self.targetId = targetId
        self._mandatory = mandatory
        self._active = active
    }
    
    public init() {
        self._mandatory = Editable(false, constant: false)
        self._active = Editable(true, constant: false)
        self._singleSelection = Editable(true, constant: false)
        self._typingSearch = Editable(true, constant: false)
        self._hideDescription = Editable(false, constant: false)
    }
}
