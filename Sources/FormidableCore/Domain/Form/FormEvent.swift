//
//  FormEvent.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 21/3/23.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Combine
public typealias FormDomainEvent = @Sendable (inout FormModel) -> Void


public protocol TemplateEvent<Template> {
    associatedtype Template: InputTemplate
    typealias Success = FormDomainEvent

    func assess(old: Template, input: Template) -> Bool
    func execute(form: FormModel, old: Template, input: Template) async throws -> FormDomainEvent
}

public protocol AsyncApplicationEvent {
    associatedtype Request: Sendable
    associatedtype Success: Sendable
    
    typealias OnSuccess =  (Request) async throws -> Success
    
    func result() async throws -> Success
}

public protocol InputEvent<Template>: AsyncApplicationEvent {
    associatedtype Template: InputTemplate
    associatedtype Request = (FormModel, Template, Template) async throws -> Success
    associatedtype Success = FormDomainEvent
    
    var task: Task<Success, Error> { get }
}

public extension InputEvent {
    func cancel() {
        task.cancel()
    }
}

public struct InputChangeEvent<Template: InputTemplate>: InputEvent {
    public typealias Request = (FormModel, Template, Template) async throws -> Success
    public typealias Success = FormDomainEvent

    public let task: Task<Success, Error>

    public init(_ event: @escaping Request, execute: @escaping OnSuccess) {
        task = Task<Success, Error> { [execute, event] in
            try await execute(event)
        }
    }
    
    public func result() async throws -> Success {
        return try await task.value
    }
}

public typealias LoadEventRequest = (FormModel) async throws -> FormDomainEvent
public typealias LoadEvent = GenericEvent<LoadEventRequest, FormDomainEvent>
public typealias SendFormRequest = (FormModel) async throws -> Void
public typealias SendFormEvent = GenericEvent<SendFormRequest, Void>

public struct GenericEvent<Request: Sendable, Success: Sendable>: AsyncApplicationEvent {
    let task: Task<Success, Error>

    public init(_ event: Request, execute: @escaping OnSuccess) {
        task = Task<Success, Error> { [execute, event] in
            try await execute(event)
        }
    }
    
    public func result() async throws -> Success {
        return try await task.value
    }
    
    public func cancel() {
        task.cancel()
    }
}
