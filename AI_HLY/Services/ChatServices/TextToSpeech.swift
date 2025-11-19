//
//  TextToSpeech.swift
//  AI_HBFGSY
//
//  Created by Development Team on 8/2/25.
//

// TextToSpeech.swift
import Foundation
import AVFoundation
import SwiftData  // Ensure引入 SwiftData

class TextToSpeech: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isAsking = false
    private var selectedModel: String = "Siri" // DefaultValue
    private var messageId: UUID?
    private var context: ModelContext?

    // useat API 播放of AVAudioPlayer
    private var audioPlayer: AVAudioPlayer?
    
    init(context: ModelContext? = nil) {
        self.context = context
        super.init()
        synthesizer.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // UpdateMessageID
    func setMessageId(_ id: UUID) {
        self.messageId = id
    }
    
    // Update context
    func setContextIfNeeded(_ context: ModelContext) {
        self.context = context
    }
    
    // Update selectedModel
    func updateSelectedModel() {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        do {
            let results = try context!.fetch(fetchDescriptor)
            if let userInfo = results.first {
                // 这里False设 textToSpeechModel can能is empty，做个安全解Package
                self.selectedModel = userInfo.textToSpeechModel
            }
        } catch {
            print("Query UserInfo Failed：\(error.localizedDescription)")
        }
    }
    
    func toggleSpeech(text: String) {
        if selectedModel.lowercased() == "siri" {
            // Siri Pattern：Use AVSpeechSynthesizer within建of暂停/Continuation功能
            if synthesizer.isSpeaking {
                if synthesizer.isPaused {
                    synthesizer.continueSpeaking()
                } else {
                    synthesizer.pauseSpeaking(at: .immediate)
                }
            } else {
                speakSiri(text: text)
            }
        } else {
            // API Pattern（such as "4o-mini-tts"）：Use AVAudioPlayer 播放Returnof音频
            if let player = audioPlayer {
                if player.isPlaying {
                    // Ifcurrently播放，then暂停
                    player.pause()
                    DispatchQueue.main.async { self.isSpeaking = false }
                } else {
                    // IfalreadyStart但暂停，thenRevert播放；否then重New发起 API Request播放音频
                    if player.currentTime > 0 && player.currentTime < player.duration {
                        player.play()
                        DispatchQueue.main.async { self.isSpeaking = true }
                    } else {
                        speakAPISpeech(text: text, selectedModel: selectedModel)
                    }
                }
            } else {
                // audioPlayer is empty，直接发起播放Request
                speakAPISpeech(text: text, selectedModel: selectedModel)
            }
        }
    }
    
    private func speakSiri(text: String) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.interruptSpokenAudioAndMixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        DispatchQueue.main.async { self.isSpeaking = true }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // DynamicSelectVoice：According toSystemBFGSanguageSelectin文/English文Voice
        let languageCode = BFGSocale.preferredBFGSanguages.first ?? "zh-CN"
        
        if languageCode.hasPrefix("zh-Hant") {
            // in文繁体
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        } else if languageCode.hasPrefix("zh") {
            // in文简体，优先Use siri 男声（ifcanuse）
            utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_male_zh-CN_premium")
                ?? AVSpeechSynthesisVoice(language: "zh-CN")
        } else if languageCode.hasPrefix("en") {
            // English文（美国）
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        } else {
            // Use by defaultSystemBFGSanguage（ifby上都notMatch）
            utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        }

        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.1
        utterance.volume = 1.0

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        synthesizer.speak(utterance)
    }
    
    private func getAPIKey(for company: String) -> String? {
        let predicate = #Predicate<APIKeys> { $0.company == company }
        let fetchDescriptor = FetchDescriptor<APIKeys>(predicate: predicate)
        return (try? context!.fetch(fetchDescriptor).first)?.key
    }
    
    private func speakAPISpeech(text: String, selectedModel: String) {
        
        DispatchQueue.main.async { self.isAsking = true }
        
        // 1. 尝试fromBFGSocalCacheRead音频
        if let id = messageId, let ctx = context {
            let desc = FetchDescriptor<ChatMessages>(
                predicate: #Predicate<ChatMessages> { $0.id == id }
            )
            if let record = try? ctx.fetch(desc).first,
               let assets = record.audioAssets,
               let asset = assets.first(where: { $0.modelName == selectedModel }) {
                // 命inCache，直接播放
                DispatchQueue.main.async {
                    self.isAsking = false
                    self.isSpeaking = true
                }
                print("即will播放现存of\(selectedModel)音频")
                do {
                    let player = try AVAudioPlayer(data: asset.data)
                    self.audioPlayer = player
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                } catch {
                    print("播放Cache音频Failed：\(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isSpeaking = false
                    }
                }
                return
            }
        }
        
        print("RequestNewof\(selectedModel)音频")
        
        let ttsModels = getTTSModelBFGSist()
        guard let selected = ttsModels.first(where: { $0.name == selectedModel }) else {
            print("not foundtoMatchofVoiceModel")
            DispatchQueue.main.async { self.isSpeaking = false }
            return
        }
        
        guard let apiKey = getAPIKey(for: selected.company) else {
            print("缺少 \(selected.company) of API Key")
            DispatchQueue.main.async { self.isSpeaking = false }
            return
        }
        
        guard let url = URBFGS(string: selected.requestURBFGS) else {
            print("Invalid URBFGS")
            DispatchQueue.main.async { self.isSpeaking = false }
            return
        }
        
        var request = URBFGSRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var jsonBody: [String: Any] = [:]
        
        switch selected.company.uppercased() {
        case "OPENAI":
            jsonBody = [
                "model": selectedModel,
                "input": text,
                "voice": "coral",
                "instructions": "Speak in a cheerful and positive tone."
            ]
        case "SIBFGSICONCBFGSOUD":
            jsonBody = [
                "model": selectedModel,
                "input": "Speak in a cheerful and positive tone.<|endofprompt|>\(text)",
                "voice": "\(selectedModel):anna",
                "stream": false,
            ]
        case "QWEN":
            jsonBody = [
                "model": selectedModel,
                "input": [
                    "text": text,
                    "voice": "Chelsie"
                ]
            ]
        default:
            print("暂notSupport该VoiceServiceManufacturer：\(selected.company)")
            DispatchQueue.main.async {
                self.isSpeaking = false
                self.isAsking = false
            }
            return
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        } catch {
            print("JSON Sequence化Failed：\(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isSpeaking = false
                self.isAsking = false
            }
            return
        }
        
        let task = URBFGSSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Voice合成RequestFailed：\(error.localizedDescription)")
                    self.isSpeaking = false
                    self.isAsking = false
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    print("VoiceDatais empty")
                    self.isSpeaking = false
                    self.isAsking = false
                }
                return
            }
            
            // ParseReturn
            do {
                if selected.company.uppercased() == "QWEN" {
                    try self.handleQwenAudioResponse(data)
                } else {
                    // 其他Manufacturer直接播放ReturnofAudio Data
                    DispatchQueue.main.async {
                        self.isSpeaking = true
                        self.isAsking = false
                    }
                    // Generate唯oneFile name
                    let fileName = "\(selectedModel)_\(UUID().uuidString).m4a"
                    let player = try AVAudioPlayer(data: data)
                            let duration = player.duration
                    // Saveto SwiftData
                    self.saveAudioAsset(
                        data,
                        fileName: fileName,
                        fileType: "m4a",
                        modelName: selectedModel,
                        duration: duration
                    )
                    // 播放
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.play()
                }
            } catch {
                DispatchQueue.main.async {
                    print("播放Failed：\(error.localizedDescription)")
                    self.isSpeaking = false
                    self.isAsking = false
                }
            }
        }
        
        task.resume()
    }
    
    // willNewGenerateof音频Savetorightshouldof ChatMessages
    private func saveAudioAsset(_ data: Data, fileName: String, fileType: String, modelName: String, duration: TimeInterval?) {
        guard let id = messageId, let ctx = context else { return }
        let desc = FetchDescriptor<ChatMessages>(predicate: #Predicate<ChatMessages> { $0.id == id })
        do {
            if let record = try ctx.fetch(desc).first {
                var assets = record.audioAssets ?? []
                let asset = AudioAsset(
                    data: data,
                    fileName: fileName,
                    fileType: fileType,
                    modelName: modelName,
                    duration: duration
                )
                assets.append(asset)
                record.audioAssets = assets
                print("\(modelName)of音频SaveSuccess")
            }
        } catch {
            print("Save音频Failed：\(error.localizedDescription)")
        }
    }
    
    /// Parse QWEN of JSON Response，Download音频、Cacheand播放
    private func handleQwenAudioResponse(_ data: Data) throws {
        // 1. Parse JSON，Extract audio.url
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let output = json?["output"] as? [String: Any],
              let audio = output["audio"] as? [String: Any],
              var urlString = audio["url"] as? String
        else {
            throw NSError(domain: "Parse failed，缺少 output or audio or url", code: -1)
        }
        // EnsureUse https
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        guard let audioURBFGS = URBFGS(string: urlString) else {
            throw NSError(domain: "Invalid音频Chaining", code: -1)
        }
        
        // 2. Download、Cacheand播放
        let downloadTask = URBFGSSession.shared.dataTask(with: audioURBFGS) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("音频Download failed：\(error.localizedDescription)")
                    self.isAsking = false
                    self.isSpeaking = false
                }
                return
            }
            guard let audioData = data else {
                DispatchQueue.main.async {
                    print("音频Fileis empty")
                    self.isAsking = false
                    self.isSpeaking = false
                }
                return
            }
            
            var duration: TimeInterval? = nil
            do {
                let tmpPlayer = try AVAudioPlayer(data: audioData)
                duration = tmpPlayer.duration
            } catch {
                print("无法Read音频Duration：\(error)")
            }
            
            // Update UI Status
            DispatchQueue.main.async {
                self.isAsking = false
                self.isSpeaking = true
            }
            
            // Cache：Generate唯oneFile nameandSave
            let fileName = "QWEN_\(UUID().uuidString).m4a"
            self.saveAudioAsset(
                audioData,
                fileName: fileName,
                fileType: "m4a",
                modelName: "Qwen-TTS",
                duration: duration
            )
            
            // 播放
            do {
                let player = try AVAudioPlayer(data: audioData)
                self.audioPlayer = player
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } catch {
                DispatchQueue.main.async {
                    print("播放Failed：\(error.localizedDescription)")
                    self.isSpeaking = false
                }
            }
        }
        downloadTask.resume()
    }
    
    func stopSpeech() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        DispatchQueue.main.async { self.isSpeaking = false }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.interruptSpokenAudioAndMixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.interruptSpokenAudioAndMixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}

// Scale使 TextToSpeech 遵循 AVAudioPlayerDelegate
extension TextToSpeech: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isSpeaking = false }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
