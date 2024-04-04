/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#if os(macOS)
import Cocoa

public enum KeyboardShortcuts {
    private static var registeredShortcuts = Set<Shortcut>()
    private static var legacyKeyDownHandlers = [Name: [() -> Void]]()
    private static var legacyKeyUpHandlers = [Name: [() -> Void]]()
    private static var shortcutsForHandlers: Set<Shortcut> {
        let shortcuts = [legacyKeyDownHandlers.keys, legacyKeyUpHandlers.keys]
            .flatMap { $0 }
            .compactMap(\.shortcut)
        
        return Set(shortcuts)
    }
    
    public static var isPaused = false
    
    private static func register(_ shortcut: Shortcut) {
        guard !registeredShortcuts.contains(shortcut) else { return }
        
        CarbonKeyboardShortcuts.register(
            shortcut,
            onKeyDown: handleOnKeyDown,
            onKeyUp: handleOnKeyUp
        )
        
        registeredShortcuts.insert(shortcut)
    }
    
    private static func registerShortcutIfNeeded(for name: Name) {
        guard let shortcut = getShortcut(for: name) else { return }
        
        register(shortcut)
    }
    
    private static func unregister(_ shortcut: Shortcut) {
        CarbonKeyboardShortcuts.unregister(shortcut)
        registeredShortcuts.remove(shortcut)
    }
    
    private static func unregisterIfNeeded(_ shortcut: Shortcut) {
        guard !shortcutsForHandlers.contains(shortcut) else { return }
        
        unregister(shortcut)
    }
    
    private static func unregisterShortcutIfNeeded(for name: Name) {
        guard let shortcut = name.shortcut else { return }
        
        unregisterIfNeeded(shortcut)
    }
    
    private static func unregisterAll() {
        CarbonKeyboardShortcuts.unregisterAll()
        registeredShortcuts.removeAll()
    }
    
    public static func removeAllHandlers() {
        let shortcutsToUnregister = shortcutsForHandlers
        
        for shortcut in shortcutsToUnregister {
            unregister(shortcut)
        }
        
        legacyKeyDownHandlers = [:]
        legacyKeyUpHandlers = [:]
    }
    
    public static func disable(_ name: Name) {
        guard let shortcut = getShortcut(for: name) else { return }
        
        unregister(shortcut)
    }
    
    public static func enable(_ name: Name) {
        guard let shortcut = getShortcut(for: name) else { return }
        
        register(shortcut)
    }
    
    public static func reset(_ names: Name...) {
        reset(names)
    }
    
    public static func reset(_ names: [Name]) {
        for name in names {
            setShortcut(name.defaultShortcut, for: name)
        }
    }
    
    public static func setShortcut(_ shortcut: Shortcut?, for name: Name) {
        if let shortcut {
            userDefaultsSet(name: name, shortcut: shortcut)
            return
        }
        if name.defaultShortcut != nil {
            userDefaultsDisable(name: name)
        } else {
            userDefaultsRemove(name: name)
        }
    }
    
    public static func getShortcut(for name: Name) -> Shortcut? {
        guard
            let data = UserDefaults.standard.string(forKey: userDefaultsKey(for: name))?.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(Shortcut.self, from: data)
        else { return nil }
        
        return decoded
    }
    
    private static func handleOnKeyDown(_ shortcut: Shortcut) {
        guard !isPaused else { return }
        
        for (name, handlers) in legacyKeyDownHandlers {
            guard getShortcut(for: name) == shortcut else { continue }
            
            for handler in handlers {
                handler()
            }
        }
    }
    
    private static func handleOnKeyUp(_ shortcut: Shortcut) {
        guard !isPaused else { return }
        
        for (name, handlers) in legacyKeyUpHandlers {
            guard getShortcut(for: name) == shortcut else { continue }
            
            for handler in handlers {
                handler()
            }
        }
    }
    
    public static func onKeyDown(for name: Name, action: @escaping () -> Void) {
        legacyKeyDownHandlers[name, default: []].append(action)
        registerShortcutIfNeeded(for: name)
    }
    
    public static func onKeyUp(for name: Name, action: @escaping () -> Void) {
        legacyKeyUpHandlers[name, default: []].append(action)
        registerShortcutIfNeeded(for: name)
    }
    
    private static let userDefaultsPrefix = "KeyboardShortcuts_"
    
    private static func userDefaultsKey(for shortcutName: Name) -> String {
        "\(userDefaultsPrefix)\(shortcutName.rawValue)"
    }
    
    public static func userDefaultsDidChange(name: Name) {
        NotificationCenter.default.post(name: .shortcutByNameDidChange, object: nil, userInfo: ["name": name])
    }
    
    public static func userDefaultsSet(name: Name, shortcut: Shortcut) {
        guard
            let data = try? JSONEncoder().encode(shortcut),
            let encoded = String(data: data, encoding: .utf8)
        else { return }
        
        if let oldShortcut = getShortcut(for: name) {
            unregister(oldShortcut)
        }
        
        register(shortcut)
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey(for: name))
        userDefaultsDidChange(name: name)
    }
    
    public static func userDefaultsDisable(name: Name) {
        guard let shortcut = getShortcut(for: name) else { return }
        
        UserDefaults.standard.set(false, forKey: userDefaultsKey(for: name))
        unregister(shortcut)
        userDefaultsDidChange(name: name)
    }
    
    public static func userDefaultsRemove(name: Name) {
        guard let shortcut = getShortcut(for: name) else { return }
        
        UserDefaults.standard.removeObject(forKey: userDefaultsKey(for: name))
        unregister(shortcut)
        userDefaultsDidChange(name: name)
    }
    
    public static func userDefaultsContains(name: Name) -> Bool {
        UserDefaults.standard.object(forKey: userDefaultsKey(for: name)) != nil
    }
}

public extension Notification.Name {
    static let shortcutByNameDidChange = Self("KeyboardShortcuts_shortcutByNameDidChange")
}
#endif
