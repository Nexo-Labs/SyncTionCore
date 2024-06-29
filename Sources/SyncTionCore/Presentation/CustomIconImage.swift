//
//  CustomIconImage.swift
//  SyncTion
//
//  Created by Rubén García Hernando on 29/6/23.
//

/*
This file is part of Formidable and is licensed under the GNU General Public License version 3.
Formidable is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import SwiftUI
import PreludePackage

public struct CustomIconImage: View {
    let icon: FormIcon
    let color: Color?
    
    public init(icon: FormIcon, color: Color?) {
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        LoadedImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(forcedColor)
            .if(icon.isStatic) { view in
                view.shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
            }
    }
    
    var forcedColor: Color? {
        switch icon {
        case let .sfsymbols(_, hex):
            if let hex {
                return Color(hex: hex)
            } else {
                return color
            }
        default:
            return color
        }
    }
    
    var LoadedImage: Image {
        switch icon {
        case let .sfsymbols(icon, _):
            return Image(systemName: icon)
        case let .data(uuid):
            let imageURL = Image.appPath?.appendingPathComponent("\(uuid.uuidString).png")
            if let imageURL, let data = try? Data(contentsOf: imageURL), let imagen = Imagen(data: data) {
                return imagen.swiftUIImage
            }
        case let .static(name, loadPng):
            return Image("\(name)\(loadPng ? "Png" : "")")
        }
        return Image(systemName: "")
    }
}
