import Carbon
import Cocoa

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    var onTrigger: (() -> Void)?
    
    private init() {}
    
    // Check if accessibility permissions are enabled
    func checkAccessibility(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func register() {
        // Unregister first if already registered
        unregister()
        
        // Create HotKey ID: Signature 'TRN1' (1414678833), ID 1
        let hotKeyID = EventHotKeyID(signature: OSType(1414678833), id: 1)
        
        // Option + T
        // Key code 17 is 'T'
        let keyCode: UInt32 = 17
        let modifiers: UInt32 = UInt32(optionKey)
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        guard status == noErr else {
            print("TranslateOne: Failed to register hotkey. Status: \(status)")
            return
        }
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handleHotkeyTriggered()
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
        
        if installStatus != noErr {
            print("TranslateOne: Failed to install hotkey event handler. Status: \(installStatus)")
        } else {
            print("TranslateOne: Global hotkey (Option+T) registered successfully.")
        }
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }
    
    private func handleHotkeyTriggered() {
        onTrigger?()
    }
    
    // Simulates Command+C and returns the copied text
    func getSelectedText() -> String? {
        if !checkAccessibility(prompt: false) {
            print("TranslateOne: Accessibility permissions not granted. Cannot simulate Copy.")
            return nil
        }
        
        let pasteboard = NSPasteboard.general
        let originalChangeCount = pasteboard.changeCount
        let originalContent = pasteboard.string(forType: .string)
        
        // Simulate Command + C
        let source = CGEventSource(stateID: .combinedSessionState)
        
        guard let cmdCDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true) else { return nil }
        cmdCDown.flags = .maskCommand
        
        guard let cmdCUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false) else { return nil }
        cmdCUp.flags = .maskCommand
        
        cmdCDown.post(tap: .cghidEventTap)
        cmdCUp.post(tap: .cghidEventTap)
        
        // Wait for pasteboard change count to increase, up to 250ms
        let startTime = Date()
        while pasteboard.changeCount == originalChangeCount && Date().timeIntervalSince(startTime) < 0.25 {
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        let selectedText = pasteboard.string(forType: .string)
        
        // Restore original clipboard contents if they existed after a brief moment
        if let original = originalContent {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.15) {
                let p = NSPasteboard.general
                p.clearContents()
                p.setString(original, forType: .string)
            }
        }
        
        return selectedText?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    deinit {
        unregister()
    }
}
