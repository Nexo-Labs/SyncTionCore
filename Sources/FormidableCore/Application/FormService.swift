//
//  FormService.swift
//  SyncTion
//
//  Created by Rubén García Hernando on 13/6/23.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation
import PreludePackage

public struct FormServiceId: Identity {
    public let hash: UUID
    
    public init(hash: UUID) {
        self.hash = hash
    }
}

public protocol FormService: Identifiable {
    var id: FormServiceId { get }
    var onChangeEvents: [any TemplateEvent] { get }
    func load(form: FormModel) async throws -> FormDomainEvent
    func send(form: FormModel) async throws -> Void
    
    var description: String { get }
    var icon: String { get }
    var scratchTemplate: FormTemplate { get }

    static var shared: Self { get }
}

public extension FormService {
    
    func delay() async throws {
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            throw FormError.api(.canceled)
        }
    }

    func filterByText(form: FormModel, input: OptionsTemplate) async throws -> FormDomainEvent {
        guard input.config.typingSearch else {
            throw FormError.event(.skip)
        }
        
        try await delay()
        
        var inputCopy = input
        inputCopy.value.filterOptions(byText: input.search)
        return { [inputCopy] form in
            form.inputs[input.id] = AnyInputTemplate(inputCopy)
//            TODO:
//            form.goToInput(by: input.id)
        }
    }

    func buildSendEvent(form: FormModel, onSuccess: @escaping (FormModel) -> Void) -> SendFormEvent {
        let event: SendFormEvent.OnSuccess = { runEvent in
            try await runEvent(form)
            onSuccess(form)
        }
        return SendFormEvent(send(form:), execute: event)
    }

    func buildOnLoadEvent(form: FormModel) -> LoadEvent {
        let request: LoadEvent.OnSuccess = { runEvent in
            try await runEvent(form)
        }
        return LoadEvent(load(form:), execute: request)
    }

    func buildOnChangeEvent<Template: InputTemplate>(form: FormModel, old: Template, input: Template) -> (any InputEvent)? {
        onChangeEvents.compactMap { event in
            buildOnChangeEvent(event, form: form, old: old, input: input)
        }.first
    }

    private func buildOnChangeEvent<Event: TemplateEvent, Template: InputTemplate>(
        _ event: Event, form: FormModel, old: Template, input: Template
    ) -> (any InputEvent)? {
        guard let input = input as? Event.Template, let old = old as? Event.Template else {
            return nil
        }
        guard event.assess(old: old, input: input) else { return nil }

        let execute: InputChangeEvent<Event.Template>.OnSuccess = { runEvent in
            try await runEvent(form, old, input)
        }

        return InputChangeEvent(event.execute, execute: execute)
    }
}
