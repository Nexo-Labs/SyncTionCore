//
//  FormRepositoryCoreData.swift
//  SyncTion (macOS)
//
//  Created by Ruben on 18.07.22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation
import Combine
import PreludePackage

public protocol Repository: AnyObject {
}

public protocol FormRepository: Repository {
    static var scratchTemplate: FormTemplate { get }

    init()
}

public extension URLSession {
    func apiDataRequest(for request: URLRequest) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await self.data(for: request)
        } catch let nsError as NSError where nsError.code == NSURLErrorCancelled {
            throw APIError.canceled
        } catch {
            throw APIError.general(CodableError(error))
        }
        
        guard let response = response as? HTTPURLResponse, (200..<299).contains(response.statusCode) else {
            throw APIError(response, data: data)
        }
        return data
    }
}

public extension Repository {

    func request<T: Decodable>(_ request: URLRequest, _ _: T.Type) async throws -> T {
        let decoder = JSONDecoder()
        let data = try await URLSession.shared.apiDataRequest(for: request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Repository: Decoding failure, data: \(data) \(T.self)")
            logger.debug("Repository: Data to UTF8: \(String(data: data, encoding: String.Encoding.utf8) ?? "")")
            throw APIError.json(data, CodableError(error))
        }
    }
    
    func transformAuthError<T>(_ integration: FormServiceId, clousure: () async throws -> T) async throws -> T {
        do {
            return try await clousure()
        } catch let error as APIError {
            guard case let .status(status, _) = error, status == 401 else {
                throw FormError.api(error)
            }
            throw FormError.auth(integration)
        }
    }
}

public enum FormEventError: Error, Codable {
    case skip
}

public enum FormError: Error, Codable {
    case invalidInputs([Header])
    case transformation
    case nonLocatedInput(Tag)
    case auth(FormServiceId)
    case api(APIError)
    case event(FormEventError)
    case genericError(CodableError)
        
    public init(_ error: Error) {
        if let error = error as? FormError {
            self = error
        } else if let error = error as? APIError {
            self = .api(error)
        } else {
            self = .genericError(CodableError(error))
        }
    }
}

public enum APIError: Error, Codable {
    case canceled
    case json(Data, CodableError)
    case general(CodableError)
    case status(Int, Data?)
    case unknown
    case noHTTPURLResponse(Data?)
    
    public init(_ urlResponse: URLResponse, data: Data? = nil) {
        if let response = urlResponse as? HTTPURLResponse {
            self = .status(response.statusCode, data)
        } else {
            self = .noHTTPURLResponse(data)
        }
    }
}

public struct CodableError: Error, Codable {
    public let localizedDescription: String
    @CodableIgnored public var error: Error?
    
    public init(_ error: Error) {
        self.localizedDescription = error.localizedDescription
        self.error = error
    }
}
