/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#if os(macOS)
import Cocoa
import Carbon.HIToolbox
import AppKit

public typealias EventShortcut = KeyboardShortcuts.Shortcut

public extension KeyboardShortcuts {
	struct Shortcut: Hashable, Codable, Equatable, Sendable {
		private static func normalizeModifiers(_ carbonModifiers: Int) -> Int {
			NSEvent.ModifierFlags(carbon: carbonModifiers).carbon
		}
        public var key: Key? { Key(rawValue: carbonKeyCode) }
        public var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(carbon: carbonModifiers) }
        public let carbonKeyCode: Int
        public let carbonModifiers: Int

        public init(_ key: Key, modifiers: NSEvent.ModifierFlags = []) {
			self.init(carbonKeyCode: key.rawValue, carbonModifiers: modifiers.carbon)
		}

        public init?(event: NSEvent) {
			guard event.isKeyEvent else { return nil }

			self.init(carbonKeyCode: Int(event.keyCode), carbonModifiers: event.modifierFlags.carbon)
		}

        public init?(name: Name) {
			guard let shortcut = getShortcut(for: name) else { return nil }
			self = shortcut
		}

        public init(carbonKeyCode: Int, carbonModifiers: Int = 0) {
			self.carbonKeyCode = carbonKeyCode
			self.carbonModifiers = Self.normalizeModifiers(carbonModifiers)
		}
	}
}

public extension KeyboardShortcuts.Shortcut {
	static var system: [Self] {
		CarbonKeyboardShortcuts.system
	}

	var isTakenBySystem: Bool {
		guard self != Self(.f12, modifiers: []) else { return false }

		return Self.system.contains(self)
	}
}

public extension KeyboardShortcuts.Shortcut {
	func menuItemWithMatchingShortcut(in menu: NSMenu) -> NSMenuItem? {
		for item in menu.items {
			var keyEquivalent = item.keyEquivalent
			var keyEquivalentModifierMask = item.keyEquivalentModifierMask

			if modifiers.contains(.shift), keyEquivalent.lowercased() != keyEquivalent {
				keyEquivalent = keyEquivalent.lowercased()
				keyEquivalentModifierMask.insert(.shift)
			}

			if keyToCharacter() == keyEquivalent, modifiers == keyEquivalentModifierMask {
				return item
			}

			if let submenu = item.submenu, let menuItem = menuItemWithMatchingShortcut(in: submenu) {
				return menuItem
			}
		}

		return nil
	}

	var takenByMainMenu: NSMenuItem? {
		guard let mainMenu = NSApp.mainMenu else { return nil }

		return menuItemWithMatchingShortcut(in: mainMenu)
	}
}

private var keyToCharacterMapping: [KeyboardShortcuts.Key: String] = [
	.return: "↩",
	.delete: "⌫",
	.deleteForward: "⌦",
	.end: "↘",
	.escape: "esc",
	.help: "?⃝",
	.home: "↖",
	.space: "⎵",
	.tab: "⇥",
	.pageUp: "⇞",
	.pageDown: "⇟",
	.upArrow: "↑",
	.rightArrow: "→",
	.downArrow: "↓",
	.leftArrow: "←",
	.f1: "F1",
	.f2: "F2",
	.f3: "F3",
	.f4: "F4",
	.f5: "F5",
	.f6: "F6",
	.f7: "F7",
	.f8: "F8",
	.f9: "F9",
	.f10: "F10",
	.f11: "F11",
	.f12: "F12",
	.f13: "F13",
	.f14: "F14",
	.f15: "F15",
	.f16: "F16",
	.f17: "F17",
	.f18: "F18",
	.f19: "F19",
	.f20: "F20"
]

private func stringFromKeyCode(_ keyCode: Int) -> String {
	String(format: "%C", keyCode)
}

private var keyToKeyEquivalentString: [KeyboardShortcuts.Key: String] = [
	.space: stringFromKeyCode(0x20),
	.f1: stringFromKeyCode(NSF1FunctionKey),
	.f2: stringFromKeyCode(NSF2FunctionKey),
	.f3: stringFromKeyCode(NSF3FunctionKey),
	.f4: stringFromKeyCode(NSF4FunctionKey),
	.f5: stringFromKeyCode(NSF5FunctionKey),
	.f6: stringFromKeyCode(NSF6FunctionKey),
	.f7: stringFromKeyCode(NSF7FunctionKey),
	.f8: stringFromKeyCode(NSF8FunctionKey),
	.f9: stringFromKeyCode(NSF9FunctionKey),
	.f10: stringFromKeyCode(NSF10FunctionKey),
	.f11: stringFromKeyCode(NSF11FunctionKey),
	.f12: stringFromKeyCode(NSF12FunctionKey),
	.f13: stringFromKeyCode(NSF13FunctionKey),
	.f14: stringFromKeyCode(NSF14FunctionKey),
	.f15: stringFromKeyCode(NSF15FunctionKey),
	.f16: stringFromKeyCode(NSF16FunctionKey),
	.f17: stringFromKeyCode(NSF17FunctionKey),
	.f18: stringFromKeyCode(NSF18FunctionKey),
	.f19: stringFromKeyCode(NSF19FunctionKey),
	.f20: stringFromKeyCode(NSF20FunctionKey)
]

fileprivate extension DispatchQueue {
    static var currentQueueLabel: String { String(cString: __dispatch_queue_get_label(nil)) }
    static var isCurrentQueueNSBackgroundActivitySchedulerQueue: Bool { currentQueueLabel.hasPrefix("com.apple.xpc.activity.")
    }
}

public extension KeyboardShortcuts.Shortcut {
	fileprivate func keyToCharacter() -> String? {
		assert(!DispatchQueue.isCurrentQueueNSBackgroundActivitySchedulerQueue, "This method cannot be used in a `NSBackgroundActivityScheduler` task")

		if let key, let character = keyToCharacterMapping[key] {
			return character
		}

		guard
			let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
			let layoutDataPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
		else {
			return nil
		}

		let layoutData = unsafeBitCast(layoutDataPointer, to: CFData.self)
		let keyLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<CoreServices.UCKeyboardLayout>.self)
		var deadKeyState: UInt32 = 0
		let maxLength = 4
		var length = 0
		var characters = [UniChar](repeating: 0, count: maxLength)

		let error = CoreServices.UCKeyTranslate(
			keyLayout,
			UInt16(carbonKeyCode),
			UInt16(CoreServices.kUCKeyActionDisplay),
			0, // No modifiers
			UInt32(LMGetKbdType()),
			OptionBits(CoreServices.kUCKeyTranslateNoDeadKeysBit),
			&deadKeyState,
			maxLength,
			&length,
			&characters
		)

		guard error == noErr else { return nil }

		return String(utf16CodeUnits: characters, count: length)
	}

    fileprivate var keyEquivalent: String {
		let keyString = keyToCharacter() ?? ""

		guard keyString.count <= 1 else {
			guard
				let key,
				let string = keyToKeyEquivalentString[key]
			else {
				return ""
			}

			return string
		}

		return keyString
	}
}

extension KeyboardShortcuts.Shortcut: CustomStringConvertible {
	public var description: String {
		modifiers.description + (keyToCharacter()?.uppercased() ?? "�")
	}
}
#endif
