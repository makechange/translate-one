import SwiftUI
import Translation
import AVFoundation

extension Notification.Name {
    static let closeTranslationHUD = Notification.Name("closeTranslationHUD")
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let cornerRadius: CGFloat
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.wantsLayer = true
        nsView.layer?.cornerRadius = cornerRadius
        nsView.layer?.masksToBounds = true
    }
}

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()
    
    @Published var isSpeaking = false
    @Published var speakingTarget: String = ""  // "source" or "translation"
    private let synthesizer = AVSpeechSynthesizer()
    
    override private init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(text: String, languageCode: String, target: String) {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
            speakingTarget = ""
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        let voice = AVSpeechSynthesisVoice(language: languageCode)
        utterance.voice = voice
        synthesizer.speak(utterance)
        isSpeaking = true
        speakingTarget = target
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        speakingTarget = ""
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        speakingTarget = ""
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        speakingTarget = ""
    }
}

struct TranslationHUDView: View {
    let sourceText: String
    
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var speechManager = SpeechManager.shared
    
    @State private var translatedText: String = ""
    @State private var isTranslating = false
    @State private var translationError: String? = nil
    @State private var detectedSourceLanguage: String? = nil
    
    @State private var configuration: TranslationSession.Configuration?
    @State private var isCopiedSource = false
    @State private var isCopiedTranslation = false
    @State private var isFallbackAttempt = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "translate")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                    Text("TranslateOne")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Source Language selector
                Picker("", selection: $settings.sourceLanguage) {
                    ForEach(SourceLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                .labelsHidden()
                .controlSize(.small)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
                
                // Target Language selector
                Picker("", selection: $settings.targetLanguage) {
                    ForEach(Language.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                .labelsHidden()
                .controlSize(.small)
                
                // Close button
                Button(action: {
                    speechManager.stop()
                    NotificationCenter.default.post(name: .closeTranslationHUD, object: nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("关闭")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider().opacity(0.3)
            
            // Scrollable Text Area
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // ── Original Text Section ──
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("原文")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        
                        Text(sourceText)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.primary.opacity(0.75))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(4)
                        
                        // Source action buttons
                        HStack(spacing: 8) {
                            actionButton(
                                icon: (speechManager.isSpeaking && speechManager.speakingTarget == "source") ? "speaker.wave.3.fill" : "speaker.wave.2",
                                label: (speechManager.isSpeaking && speechManager.speakingTarget == "source") ? "停止" : "朗读",
                                isActive: speechManager.isSpeaking && speechManager.speakingTarget == "source"
                            ) {
                                let langCode = detectedSourceLanguage ?? "en-US"
                                speechManager.speak(text: sourceText, languageCode: langCode, target: "source")
                            }
                            
                            actionButton(
                                icon: isCopiedSource ? "checkmark" : "doc.on.doc",
                                label: isCopiedSource ? "已复制" : "复制",
                                isActive: isCopiedSource
                            ) {
                                copyText(sourceText, flag: $isCopiedSource)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Gradient Divider
                    LinearGradient(
                        colors: [.blue.opacity(0.5), .purple.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1.5)
                    .padding(.horizontal, 16)
                    
                    // ── Translation Section ──
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("译文")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor.opacity(0.9))
                                .textCase(.uppercase)
                            Spacer()
                        }
                        
                        if isTranslating {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("翻译中...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        } else if let error = translationError {
                            Text(error)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(translatedText.isEmpty ? "正在准备翻译..." : translatedText)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineSpacing(4)
                        }
                        
                        // Translation action buttons
                        HStack(spacing: 8) {
                            actionButton(
                                icon: (speechManager.isSpeaking && speechManager.speakingTarget == "translation") ? "speaker.wave.3.fill" : "speaker.wave.2",
                                label: (speechManager.isSpeaking && speechManager.speakingTarget == "translation") ? "停止" : "朗读",
                                isActive: speechManager.isSpeaking && speechManager.speakingTarget == "translation"
                            ) {
                                guard !translatedText.isEmpty else { return }
                                speechManager.speak(text: translatedText, languageCode: settings.targetLanguage.rawValue, target: "translation")
                            }
                            .opacity(translatedText.isEmpty ? 0.4 : 1)
                            .disabled(translatedText.isEmpty)
                            
                            actionButton(
                                icon: isCopiedTranslation ? "checkmark" : "doc.on.doc",
                                label: isCopiedTranslation ? "已复制" : "复制",
                                isActive: isCopiedTranslation
                            ) {
                                guard !translatedText.isEmpty else { return }
                                copyText(translatedText, flag: $isCopiedTranslation)
                            }
                            .opacity(translatedText.isEmpty ? 0.4 : 1)
                            .disabled(translatedText.isEmpty)
                            
                            Spacer()
                            
                            // Quick language swap
                            Button(action: quickSwapLanguage) {
                                Image(systemName: "arrow.2.squarepath")
                                    .font(.subheadline)
                                    .padding(5)
                                    .background(Color.primary.opacity(0.06))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .help("中英互换")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow, cornerRadius: 12)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            triggerTranslation()
        }
        .onChange(of: settings.targetLanguage) {
            triggerTranslation()
        }
        .onChange(of: settings.sourceLanguage) {
            triggerTranslation()
        }
        .onChange(of: sourceText) {
            triggerTranslation()
        }
        .translationTask(configuration) { session in
            do {
                isTranslating = true
                translationError = nil
                let response = try await session.translate(sourceText)
                translatedText = response.targetText
                detectedSourceLanguage = response.sourceLanguage.maximalIdentifier
                isTranslating = false
            } catch {
                if settings.sourceLanguage == .auto && !isFallbackAttempt {
                    print("TranslateOne: Auto-detection failed, falling back to English")
                    isFallbackAttempt = true
                    configuration = TranslationSession.Configuration(
                        source: Locale.Language(identifier: "en-US"),
                        target: settings.targetLanguage.localeLanguage
                    )
                } else {
                    isTranslating = false
                    translationError = "翻译失败: \(error.localizedDescription)"
                    print("TranslateOne: translation failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Reusable action button
    @ViewBuilder
    private func actionButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundColor(isActive ? .accentColor : .primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(isActive ? 0.1 : 0.06))
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    private func triggerTranslation() {
        guard !sourceText.isEmpty else { return }
        translatedText = ""
        isFallbackAttempt = false
        configuration = TranslationSession.Configuration(
            source: settings.sourceLanguage.localeLanguage,
            target: settings.targetLanguage.localeLanguage
        )
    }
    
    private func copyText(_ text: String, flag: Binding<Bool>) {
        let p = NSPasteboard.general
        p.clearContents()
        p.setString(text, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            flag.wrappedValue = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                flag.wrappedValue = false
            }
        }
    }
    
    private func quickSwapLanguage() {
        speechManager.stop()
        
        let currentTarget = settings.targetLanguage
        let currentSourceRaw = settings.sourceLanguage == .auto ? (detectedSourceLanguage ?? "en-US") : settings.sourceLanguage.rawValue
        
        let newTarget = Language(rawValue: currentSourceRaw) ?? .en_US
        let newSource = SourceLanguage(rawValue: currentTarget.rawValue) ?? .auto
        
        settings.sourceLanguage = newSource
        settings.targetLanguage = newTarget
    }
}
