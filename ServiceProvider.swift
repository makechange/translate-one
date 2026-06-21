import Cocoa

extension Notification.Name {
    static let didReceiveTextToTranslate = Notification.Name("didReceiveTextToTranslate")
}

class ServiceProvider: NSObject {
    @objc func translateService(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            return
        }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .didReceiveTextToTranslate,
                object: trimmed
            )
        }
    }
}
