import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let serviceProvider = ServiceProvider()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Setup Status Item in Menu Bar
        setupStatusItem()
        
        // 2. Register macOS Services provider
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
        
        // 3. Register Global Hotkey
        setupHotkey()
        
        // 4. Listen to incoming service notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleServiceTranslation(_:)),
            name: .didReceiveTextToTranslate,
            object: nil
        )
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "translate", accessibilityDescription: "TranslateOne")
            button.image?.isTemplate = true
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        let translateClipboardItem = NSMenuItem(
            title: "翻译剪贴板内容",
            action: #selector(translateClipboard),
            keyEquivalent: "c"
        )
        translateClipboardItem.keyEquivalentModifierMask = [.option, .shift]
        menu.addItem(translateClipboardItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Target Language Submenu
        let langMenu = NSMenu()
        let settings = SettingsManager.shared
        for lang in Language.allCases {
            let item = NSMenuItem(
                title: lang.displayName,
                action: #selector(changeTargetLanguage(_:)),
                keyEquivalent: ""
            )
            item.representedObject = lang
            item.state = (lang == settings.targetLanguage) ? .on : .off
            langMenu.addItem(item)
        }
        
        let targetLangItem = NSMenuItem(title: "目标语言", action: nil, keyEquivalent: "")
        targetLangItem.submenu = langMenu
        menu.addItem(targetLangItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let hotkeyInfo = NSMenuItem(title: "全局快捷键: Option + T (需辅助功能权限)", action: nil, keyEquivalent: "")
        hotkeyInfo.isEnabled = false
        menu.addItem(hotkeyInfo)
        
        let permissionItem = NSMenuItem(
            title: "检查 / 申请辅助功能权限",
            action: #selector(checkOrRequestPermissions),
            keyEquivalent: ""
        )
        menu.addItem(permissionItem)
        
        let serviceHelpItem = NSMenuItem(
            title: "设置系统服务快捷键 (推荐 - 免权限)...",
            action: #selector(showServiceHelp),
            keyEquivalent: ""
        )
        menu.addItem(serviceHelpItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "退出 TranslateOne", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    private func setupHotkey() {
        HotkeyManager.shared.onTrigger = { [weak self] in
            guard let self = self else { return }
            
            if !HotkeyManager.shared.checkAccessibility(prompt: false) {
                self.showPermissionRequestAlert()
                return
            }
            
            // Runs copy simulation and gets selection
            if let selectedText = HotkeyManager.shared.getSelectedText(), !selectedText.isEmpty {
                TranslationHUDController.shared.show(withText: selectedText)
            }
        }
        
        HotkeyManager.shared.register()
    }
    
    @objc private func handleServiceTranslation(_ notification: Notification) {
        if let text = notification.object as? String {
            TranslationHUDController.shared.show(withText: text)
        }
    }
    
    @objc private func translateClipboard() {
        if let text = NSPasteboard.general.string(forType: .string), !text.isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                TranslationHUDController.shared.show(withText: trimmed)
            }
        }
    }
    
    @objc private func changeTargetLanguage(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? Language else { return }
        SettingsManager.shared.targetLanguage = lang
        
        if let submenu = sender.menu {
            for item in submenu.items {
                if let itemLang = item.representedObject as? Language {
                    item.state = (itemLang == lang) ? .on : .off
                }
            }
        }
    }
    
    @objc private func checkOrRequestPermissions() {
        let granted = HotkeyManager.shared.checkAccessibility(prompt: true)
        let alert = NSAlert()
        alert.messageText = granted ? "辅助功能权限已启用" : "辅助功能权限未启用"
        alert.informativeText = granted 
            ? "全局快捷键 Option+T 已激活。在任意软件中选中文本，按下 Option+T 即可弹出翻译窗口。" 
            : "若要使用快捷键 Option+T，请在系统设置中为 TranslateOne 开启“辅助功能”权限。"
        alert.addButton(withTitle: "好的")
        if !granted {
            alert.addButton(withTitle: "打开系统设置")
        }
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showPermissionRequestAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "全局快捷键 Option+T 需要模拟“拷贝 (Cmd+C)”操作来获取选中文本。请在系统设置中为 TranslateOne 开启“辅助功能”权限。\n\n提示：您也可以点击右键菜单的“服务 -> Translate with TranslateOne”进行翻译，该方式完全免系统权限！"
        alert.addButton(withTitle: "去设置")
        alert.addButton(withTitle: "暂不")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func showServiceHelp() {
        let alert = NSAlert()
        alert.messageText = "设置系统服务快捷键 (免权限)"
        alert.informativeText = "1. 打开“系统设置 -> 键盘 -> 键盘快捷键 -> 服务”。\n2. 展开“文本”分类，找到 “Translate with TranslateOne”。\n3. 双击其右侧空白处，为其设置您喜欢的快捷键 (例如 Command+Shift+T)。\n4. 设置完成后，在任意软件中选中文本并按下此快捷键即可开始翻译！"
        alert.addButton(withTitle: "好的")
        alert.addButton(withTitle: "打开键盘设置")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard")!
            NSWorkspace.shared.open(url)
        }
    }
}
