# TranslateOne 

[English](#english) | [中文](#中文)

---

## English

TranslateOne is a lightweight, clean, and modern macOS menu-bar utility that provides instant screen and clipboard translation using Apple's native **Translation Framework** (introduced in macOS 15) and text-to-speech (TTS) engines.

### Key Features
* **Native Translation**: Powered by macOS 15+ System Translation Framework for offline and secure translation.
* **Instant Clipboard Translation**: Copy any text, press Option+Shift+C (default), and the HUD pops up instantly next to your cursor.
* **Interactive HUD Panel**: Modern translucent panel (`NSVisualEffectView`) supporting dragging, edge-corner resizing, and automatic shadow updates.
* **Advanced Text-to-Speech (TTS)**: Dedicated original and translated speech synthesis. Original text uses auto-detected languages, while translation uses target language voices.
* **Auto-Language Fallback**: Intelligent fallback system that defaults to English translation if automatic language detection fails (common for short words).
* **Mac App Icon**: Sleek macOS-compliant squircle application icon with a transparent background.

### System Requirements
* **macOS 15.0 (Sequoia)** or later.
* **Swift 6.0** (if compiling from source).

---

## 中文

TranslateOne 是一款轻量、现代且优雅的 macOS 菜单栏快捷翻译工具。基于 macOS 15 原生 **Translation 框架** 和系统级语音合成（TTS）引擎，为您提供瞬时唤起的划词/剪贴板翻译体验。

### 主要功能
* **系统原生翻译**：基于 macOS 15+ 原生 Translation 框架，支持离线高速翻译，保障隐私安全。
* **剪贴板瞬时翻译**：复制任意文本，按下 `Option + Shift + C`（默认快捷键），翻译 HUD 面板即刻在鼠标旁唤起。
* **现代化 HUD 交互**：高斯模糊磨砂玻璃（`NSVisualEffectView`）面板，支持任意拖拽移动、边缘拉伸缩放，完美契合 macOS 视觉规范。
* **独立双语朗读 (TTS)**：原文与译文配有独立朗读按钮，原文自动匹配识别语种（如美式英语发音），译文使用目标语种发音。
* **智能故障恢复**：自动检测源语言，若遇极短词汇判定失败，会自动静默退回到 `English` 进行二次翻译，彻底杜绝系统报错弹窗。
* **macOS 规范图标**：完美适配最新 macOS 规范的圆角矩形（Squircle）应用程序图标，支持系统暗色模式与透明边缘。

### 系统要求
* **macOS 15.0 (Sequoia)** 或更高版本。
* **Swift 6.0** 或以上版本（如需从源码编译）。

---

## Installation & Setup / 安装与配置

### 1. Build from Source / 源码编译

Open Terminal, clone the repository, and run the compilation script:

```bash
# Clone the repository
git clone git@github.com:makechange/translate-one.git
cd translate-one

# Compile and package
./build.sh
```

This compiles the source code and creates a standalone application bundle `TranslateOne.app` in the project root. You can drag it into your `/Applications` directory.

### 2. Grant Accessibility Permission / 授予辅助功能权限

To allow the global hotkey (`Option + Shift + C`) to function, the application requires Accessibility permissions:

1. Launch `TranslateOne.app`.
2. A prompt will appear asking for Accessibility permissions.
3. Open **System Settings > Privacy & Security > Accessibility**.
4. Toggle the switch to **On** for **TranslateOne**.
5. Restart the application if necessary.

---

## Development & Architecture / 项目结构与规范

### File Structure / 文件层级

```
.
├── Info.plist                     # App configuration, Bundle ID & OS services
├── AppIcon.icns                   # 1024x1024 macOS standard squircle app icon
├── build.sh                       # Ad-Hoc command-line compilation script
├── main.swift                     # Application entry point
├── AppDelegate.swift              # App lifecycle, Status Bar menu items
├── ServiceProvider.swift          # OS Service integration (Services Menu option)
├── HotkeyManager.swift            # Carbon Hotkey registry for global shortcuts
├── Language.swift                 # Supported locale languages & SettingsManager (UserDefaults)
├── TranslationHUDController.swift  # Floating NSPanel management (size, position, transparency)
└── TranslationHUDView.swift       # SwiftUI View for HUD layouts, translation task, and speech engine
```

### Xcode Project Note / 关于 Xcode 工程

Currently, this repository compiles using a command-line script (`build.sh`) directly calling `swiftc`. This setup is highly lightweight, fast, and dependency-free.

To conform to Apple's **standard IDE development practices**:
* Developers typically wrap these source files in a `.xcodeproj` (Xcode Project) structure to facilitate graphical storyboard design, visual target/signing setup, and App Store distribution.
* If you plan to expand the app (e.g. adding sandboxing or distributing via the App Store), creating an Xcode project is highly recommended.
