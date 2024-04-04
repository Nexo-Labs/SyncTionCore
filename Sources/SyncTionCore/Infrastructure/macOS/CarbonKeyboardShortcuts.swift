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

private func carbonKeyboardShortcutsEventHandler(
    eventHandlerCall: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
	CarbonKeyboardShortcuts.handleEvent(event)
}

public enum CarbonKeyboardShortcuts {
	private struct HotKey {
		let shortcut: KeyboardShortcuts.Shortcut
		let carbonHotKeyId: Int
		let carbonHotKey: EventHotKeyRef
		let onKeyDown: (KeyboardShortcuts.Shortcut) -> Void
		let onKeyUp: (KeyboardShortcuts.Shortcut) -> Void
	}

	private static var hotKeys = [Int: HotKey]()
	private static let hotKeySignature: UInt32 = 1397967699

	private static var hotKeyId = 0
	private static var eventHandler: EventHandlerRef?

	private static func setUpEventHandlerIfNeeded() {
		guard eventHandler == nil, let dispatcher = GetEventDispatcherTarget() else { return }

		let eventSpecs = [
			EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
			EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
		]

		InstallEventHandler(
			dispatcher,
			carbonKeyboardShortcutsEventHandler,
			eventSpecs.count,
			eventSpecs,
			nil,
			&eventHandler
		)
	}

    public static func register(
		_ shortcut: KeyboardShortcuts.Shortcut,
		onKeyDown: @escaping (KeyboardShortcuts.Shortcut) -> Void,
		onKeyUp: @escaping (KeyboardShortcuts.Shortcut) -> Void
	) {
		hotKeyId += 1

		var eventHotKey: EventHotKeyRef?
		let registerError = RegisterEventHotKey(
			UInt32(shortcut.carbonKeyCode),
			UInt32(shortcut.carbonModifiers),
			EventHotKeyID(signature: hotKeySignature, id: UInt32(hotKeyId)),
			GetEventDispatcherTarget(),
			0,
			&eventHotKey
		)

		guard registerError == noErr, let carbonHotKey = eventHotKey else { return }

		hotKeys[hotKeyId] = HotKey(
			shortcut: shortcut,
            carbonHotKeyId: hotKeyId,
			carbonHotKey: carbonHotKey,
			onKeyDown: onKeyDown,
			onKeyUp: onKeyUp
		)

		setUpEventHandlerIfNeeded()
	}

	private static func unregisterHotKey(_ hotKey: HotKey) {
		UnregisterEventHotKey(hotKey.carbonHotKey)
		hotKeys.removeValue(forKey: hotKey.carbonHotKeyId)
	}

    public static func unregister(_ shortcut: KeyboardShortcuts.Shortcut) {
		for hotKey in hotKeys.values where hotKey.shortcut == shortcut {
			unregisterHotKey(hotKey)
		}
	}

    public static func unregisterAll() {
		for hotKey in hotKeys.values {
			unregisterHotKey(hotKey)
		}
	}

	fileprivate static func handleEvent(_ event: EventRef?) -> OSStatus {
		guard let event else { return OSStatus(eventNotHandledErr) }

		var eventHotKeyId = EventHotKeyID()
		let error = GetEventParameter(
			event,
			UInt32(kEventParamDirectObject),
			UInt32(typeEventHotKeyID),
			nil,
			MemoryLayout<EventHotKeyID>.size,
			nil,
			&eventHotKeyId
		)

		guard error == noErr else { return error }

        guard eventHotKeyId.signature == hotKeySignature, let hotKey = hotKeys[Int(eventHotKeyId.id)] else {
			return OSStatus(eventNotHandledErr)
		}

		switch Int(GetEventKind(event)) {
		case kEventHotKeyPressed:
			hotKey.onKeyDown(hotKey.shortcut)
			return noErr
		case kEventHotKeyReleased:
			hotKey.onKeyUp(hotKey.shortcut)
			return noErr
		default:
			break
		}

		return OSStatus(eventNotHandledErr)
	}
}

public extension CarbonKeyboardShortcuts {
	static var system: [KeyboardShortcuts.Shortcut] {
		var shortcutsUnmanaged: Unmanaged<CFArray>?
		guard
			CopySymbolicHotKeys(&shortcutsUnmanaged) == noErr,
			let shortcuts = shortcutsUnmanaged?.takeRetainedValue() as? [[String: Any]]
		else { return [] }

		return shortcuts.compactMap {
			guard
				($0[kHISymbolicHotKeyEnabled] as? Bool) == true,
				let carbonKeyCode = $0[kHISymbolicHotKeyCode] as? Int,
				let carbonModifiers = $0[kHISymbolicHotKeyModifiers] as? Int
			else { return nil }

			return KeyboardShortcuts.Shortcut(
				carbonKeyCode: carbonKeyCode,
				carbonModifiers: carbonModifiers
			)
		}
	}
}

public extension NSEvent {
    var isKeyEvent: Bool { type == .keyDown || type == .keyUp }
}

public extension NSEvent.ModifierFlags {
    var shortcutFiltered: NSEvent.ModifierFlags {
        self.intersection(.deviceIndependentFlagsMask)
            .subtracting([.capsLock, .numericPad, .function])
    }

    var carbon: Int {
        var modifierFlags = 0

        if contains(.control) { modifierFlags |= controlKey }
        if contains(.option) { modifierFlags |= optionKey }
        if contains(.shift) { modifierFlags |= shiftKey }
        if contains(.command) { modifierFlags |= cmdKey }

        return modifierFlags
    }

    init(carbon: Int) {
        self.init()

        if carbon & controlKey == controlKey {
            insert(.control)
        }

        if carbon & optionKey == optionKey {
            insert(.option)
        }

        if carbon & shiftKey == shiftKey {
            insert(.shift)
        }

        if carbon & cmdKey == cmdKey {
            insert(.command)
        }
    }
}

extension NSEvent.ModifierFlags: CustomStringConvertible {
    public var description: String {
        var description = ""

        if contains(.control) {
            description += "⌃"
        }

        if contains(.option) {
            description += "⌥"
        }

        if contains(.shift) {
            description += "⇧"
        }

        if contains(.command) {
            description += "⌘"
        }

        if contains(.function) {
            description += "🌐\u{FE0E}"
        }

        return description
    }
}

public extension NSEvent.SpecialKey {
    static let functionKeys: Set<Self> = [
        .f1,
        .f2,
        .f3,
        .f4,
        .f5,
        .f6,
        .f7,
        .f8,
        .f9,
        .f10,
        .f11,
        .f12,
        .f13,
        .f14,
        .f15,
        .f16,
        .f17,
        .f18,
        .f19,
        .f20,
    ]

    var isFunctionKey: Bool { Self.functionKeys.contains(self) }
}

#endif
