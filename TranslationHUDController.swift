import Cocoa
import SwiftUI

class TranslationHUDController: NSWindowController {
    static let shared = TranslationHUDController()
    
    private var clickMonitor: Any?
    private var localClickMonitor: Any?
    
    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
            // Use .titled + .fullSizeContentView so macOS provides native resize handles at all edges/corners.
            // .borderless alone prevents the resize cursor and drag handles from appearing.
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: true
        )
        
        // Hide the title bar visually while keeping resize capability
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.minSize = NSSize(width: 360, height: 220)
        
        super.init(window: panel)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closeHUD),
            name: .closeTranslationHUD,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(withText text: String) {
        guard let panel = window as? NSPanel else { return }
        
        // Setup SwiftUI View
        let hostingView = NSHostingView(rootView: TranslationHUDView(sourceText: text))
        hostingView.frame = NSRect(origin: .zero, size: NSSize(width: panel.frame.width > 0 ? panel.frame.width : 440, height: 400))
        panel.contentView = hostingView
        
        let fittingH = max(hostingView.fittingSize.height, 220)
        let w = max(panel.frame.width > 10 ? panel.frame.width : 440, 360)
        panel.setContentSize(NSSize(width: w, height: fittingH))
        
        positionNearCursor(size: panel.frame.size)
        
        // Ensure standard buttons stay hidden after content swap
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Show panel with smooth fade in
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
        
        setupClickMonitors()
    }
    
    @objc func closeHUD() {
        guard let panel = window as? NSPanel, panel.isVisible else { return }
        
        removeClickMonitors()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
            panel.contentView = nil
        })
    }
    
    private func positionNearCursor(size: NSSize) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        
        guard let activeScreen = screen else { return }
        let screenFrame = activeScreen.visibleFrame
        
        var x = mouseLocation.x + 12
        var y = mouseLocation.y - size.height - 12
        
        if x + size.width > screenFrame.maxX {
            x = mouseLocation.x - size.width - 12
        }
        if x < screenFrame.minX {
            x = screenFrame.minX + 12
        }
        
        if y < screenFrame.minY {
            y = mouseLocation.y + 12
        }
        if y + size.height > screenFrame.maxY {
            y = screenFrame.maxY - size.height - 12
        }
        
        window?.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func setupClickMonitors() {
        removeClickMonitors()
        
        // Close on clicking outside the panel (global click in another app)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            let mouseLocation = NSEvent.mouseLocation
            if self.isClickOnAllowedWindow(at: mouseLocation) {
                return
            }
            self.closeHUD()
        }
        
        // Close on clicking outside the panel (local click inside our own app)
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.window else { return event }
            let clickLocation = event.locationInWindow
            let localPoint = panel.contentView?.convert(clickLocation, from: nil) ?? .zero
            
            if panel.contentView?.bounds.contains(localPoint) ?? false {
                return event
            }
            
            let mouseLocation = NSEvent.mouseLocation
            if self.isClickOnAllowedWindow(at: mouseLocation) {
                return event
            }
            
            self.closeHUD()
            return event
        }
    }
    
    private func isClickOnAllowedWindow(at point: NSPoint) -> Bool {
        guard let primaryScreen = NSScreen.screens.first else { return false }
        let cgPoint = CGPoint(x: point.x, y: primaryScreen.frame.height - point.y)
        
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        
        for windowInfo in windowList {
            guard let pid = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any],
                  let rect = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else {
                continue
            }
            
            if rect.contains(cgPoint) {
                if pid == getpid() {
                    return true
                }
                
                if let ownerName = windowInfo[kCGWindowOwnerName as String] as? String {
                    let name = ownerName.lowercased()
                    if name.contains("translation") || name.contains("translate") || name.contains("coreservices") {
                        return true
                    }
                }
                
                if let windowName = windowInfo[kCGWindowName as String] as? String {
                    let title = windowName.lowercased()
                    if title.contains("translation") || title.contains("translate") {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func removeClickMonitors() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }
    
    deinit {
        removeClickMonitors()
        NotificationCenter.default.removeObserver(self)
    }
}
