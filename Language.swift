import Foundation
import Translation

enum Language: String, CaseIterable, Identifiable {
    case zh_CN = "zh-CN"
    case zh_TW = "zh-TW"
    case en_US = "en-US"
    case ja_JP = "ja-JP"
    case ko_KR = "ko-KR"
    case es_ES = "es-ES"
    case fr_FR = "fr-FR"
    case de_DE = "de-DE"
    case ru_RU = "ru-RU"
    case pt_BR = "pt-BR"
    case it_IT = "it-IT"
    case ar_AE = "ar-AE"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .zh_CN: return "简体中文"
        case .zh_TW: return "繁體中文"
        case .en_US: return "English"
        case .ja_JP: return "日本語"
        case .ko_KR: return "한국어"
        case .es_ES: return "Español"
        case .fr_FR: return "Français"
        case .de_DE: return "Deutsch"
        case .ru_RU: return "Русский"
        case .pt_BR: return "Português"
        case .it_IT: return "Italiano"
        case .ar_AE: return "العربية"
        }
    }
    
    var localeLanguage: Locale.Language {
        return Locale.Language(identifier: self.rawValue)
    }
}

enum SourceLanguage: String, CaseIterable, Identifiable {
    case auto = "auto"
    case zh_CN = "zh-CN"
    case zh_TW = "zh-TW"
    case en_US = "en-US"
    case ja_JP = "ja-JP"
    case ko_KR = "ko-KR"
    case es_ES = "es-ES"
    case fr_FR = "fr-FR"
    case de_DE = "de-DE"
    case ru_RU = "ru-RU"
    case pt_BR = "pt-BR"
    case it_IT = "it-IT"
    case ar_AE = "ar-AE"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .auto: return "自动检测"
        case .zh_CN: return "简体中文"
        case .zh_TW: return "繁體中文"
        case .en_US: return "English"
        case .ja_JP: return "日本語"
        case .ko_KR: return "한국어"
        case .es_ES: return "Español"
        case .fr_FR: return "Français"
        case .de_DE: return "Deutsch"
        case .ru_RU: return "Русский"
        case .pt_BR: return "Português"
        case .it_IT: return "Italiano"
        case .ar_AE: return "العربية"
        }
    }
    
    var localeLanguage: Locale.Language? {
        if self == .auto { return nil }
        return Locale.Language(identifier: self.rawValue)
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var targetLanguage: Language {
        didSet {
            UserDefaults.standard.set(targetLanguage.rawValue, forKey: "TargetLanguage")
        }
    }
    
    @Published var sourceLanguage: SourceLanguage {
        didSet {
            UserDefaults.standard.set(sourceLanguage.rawValue, forKey: "SourceLanguage")
        }
    }
    
    private init() {
        // Load target language
        if let saved = UserDefaults.standard.string(forKey: "TargetLanguage"),
           let lang = Language(rawValue: saved) {
            self.targetLanguage = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? ""
            if preferred.contains("zh") {
                self.targetLanguage = .zh_CN
            } else {
                self.targetLanguage = .en_US
            }
        }
        
        // Load source language
        if let savedSource = UserDefaults.standard.string(forKey: "SourceLanguage"),
           let lang = SourceLanguage(rawValue: savedSource) {
            self.sourceLanguage = lang
        } else {
            self.sourceLanguage = .auto
        }
    }
}
