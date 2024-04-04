/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#if os(macOS)
public extension KeyboardShortcuts {
	struct Name: Hashable {
		typealias Shortcut = KeyboardShortcuts.Shortcut

        public let rawValue: String
		let defaultShortcut: Shortcut?
		var shortcut: Shortcut? { KeyboardShortcuts.getShortcut(for: self) }

		init(_ name: String, default defaultShortcut: Shortcut? = nil) {
			self.rawValue = name
			self.defaultShortcut = defaultShortcut

			if let defaultShortcut, !userDefaultsContains(name: self) {
				setShortcut(defaultShortcut, for: self)
			}
		}
	}
}

extension KeyboardShortcuts.Name: RawRepresentable {
	public init?(rawValue: String) {
		self.init(rawValue)
	}
}
#endif
