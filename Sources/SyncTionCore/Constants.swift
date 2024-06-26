//
//  Constants.swift
//  
//
//  Created by Rubén García Hernando on 26/8/23.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

fileprivate let docDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

public extension URL {
    static let todoistAuth: (String) -> URL = { code in
        URL(string: "https://todoist.com/oauth/authorize?client_id=\(code)&scope=data:read,task:add")!
    }
    static let notionAuth: (String) -> URL = { code in
        URL(string: "https://api.notion.com/v1/oauth/authorize?client_id=\(code)&response_type=code&owner=user")!
    }
    static let formsHeaderFile: URL = {
#if DEBUG
        let formsHeaderFilename: String = "formsHeader_debug.dat"
#else
        let formsHeaderFilename: String = "formsHeader.dat"
#endif
        return docDirectoryURL
            .appendingPathComponent(formsHeaderFilename)
    }()
    
    static let lastExecutionFile: URL = {
#if DEBUG
        let lastExecutionFilename: String = "last_execution_debug.dat"
#else
        let lastExecutionFilename: String = "last_execution.dat"
#endif
        return docDirectoryURL
            .appendingPathComponent(lastExecutionFilename)
    }()
    
    static func formFile(id: FormTemplateId) -> URL {
        docDirectoryURL.appendingPathComponent("\(id.uuidString).dat")
    }
}
