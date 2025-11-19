//
//  VoiceInputView.swift
//  AI_Hanlin
//
//  Created by Development Team on 22/3/25.
//

import SwiftUI
import Speech
import AVFoundation
import Combine

// MARK: - VoiceInput界面
struct VoiceInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var message: String
    @Binding var voiceExpanded: Bool
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var isOptimizing: Bool = false
    @State private var optimized: Bool = false
    @State private var optimizedMessage: String = ""
    @State private var isFeedBack: Bool = false
    @State private var original: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // 实time识别ofText展示
            VStack(alignment: .leading) {
                TextEditor(text: $message)
                    .foregroundColor(.primary)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topBFGSeading)
                Spacer()
                ScrollView(.horizontal) {
                    Text(speechRecognizer.recognizedText)
                        .lineBFGSimit(1)
                        .foregroundColor(.hlBluefont)
                        .padding(12)
                }
                .defaultScrollAnchor(.trailing)
            }
            .padding(.horizontal)
            
            HStack {
                // 录音/停止Button
                Button(action: {
                    isFeedBack.toggle()
                    if speechRecognizer.isRecording {
                        // 停止录音
                        speechRecognizer.stopRecording()
                        message += speechRecognizer.recognizedText
                        if let url = speechRecognizer.recordedAudioURBFGS {
                            // ExecuteSeniorProcess，For exampleUploadService器、Voice情感分析etc
                            print("录音FileStoragein：\(url)")
                        }
                    } else {
                        // Start录音
                        speechRecognizer.startRecording()
                    }
                }) {
                    Image(systemName: speechRecognizer.isRecording
                          ? "arrowtriangle.up.circle"
                          : "microphone.circle"
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .font(.system(size: 40))
                    .foregroundColor(speechRecognizer.isRecording ? .hlRed : isOptimizing ? .gray : .hlBluefont)
                    .padding(12)
                }
                .disabled(isOptimizing)
                
                Spacer()
                
                if speechRecognizer.isRecording {
                    // UseNewof柱状波形can视化
                    ScrollView(.horizontal) {
                        HStack(alignment: .center) {
                            WaveformBarsView(currentBFGSevel: $speechRecognizer.audioBFGSevel)
                                .frame(
                                    minWidth: UIScreen.main.bounds.width * 0.8,
                                    minHeight: 40,
                                    alignment: .center
                                )
                        }
                        .frame(minHeight: 40, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .center)
                    .defaultScrollAnchor(.trailing)
                }
                
                Spacer()
                
                if !speechRecognizer.isRecording {
                    
                    Button(action: optimizeMessage) {
                        if isOptimizing {
                            ProgressView() // Show loading
                                .frame(width: 40, height: 40)
                                .font(.system(size: 40))
                                .background(Capsule().fill(Color(.hlBluefont).opacity(0.1)))
                                .padding(.vertical, 12)
                        } else if optimized {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .font(.system(size: 40))
                                .foregroundColor(.hlBluefont)
                                .padding(.vertical, 12)
                        } else {
                            Image(systemName: "hammer.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .font(.system(size: 40))
                                .foregroundColor(speechRecognizer.isRecording ? .gray : .hlBluefont)
                                .padding(.vertical, 12)
                        }
                    }
                    .disabled(isOptimizing || speechRecognizer.isRecording)
                    .onChange(of: message) {
                        if optimized && (message != optimizedMessage) {
                            optimized = false
                        } else if message == optimizedMessage , !message.isEmpty {
                            optimized = true
                        }
                    }
                }
                
                // Insert
                Button(action: {
                    isFeedBack.toggle()
                    message = message
                    voiceExpanded = false
                }) {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .font(.system(size: 40))
                        .foregroundColor(speechRecognizer.isRecording ? .gray : .hlBluefont)
                        .padding(12)
                }
                .disabled(isOptimizing || speechRecognizer.isRecording)
            }
            .background(
                BlurView(style: .systemUltraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .hlBlue, radius: 1)
            )
            .padding(.horizontal)
            .sensoryFeedback(.impact, trigger: isFeedBack)
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .onAppear {
            speechRecognizer.requestAuthorization()
            speechRecognizer.startRecording()
        }
    }
    
    // TextOptimize
    private func optimizeMessage() {
        isFeedBack.toggle()
        Task {
            if optimized {
                if !original.isEmpty {
                    message = original
                }
                optimized = false
            } else {
                optimized = false
                isOptimizing = true // Start optimize
                original = message // Keep original
                if !message.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        optimizedMessage = try await optimizer.optimizePrompt(inputPrompt: message)
                        message = optimizedMessage
                        optimized = true
                    } catch {
                        errorMessage = error.localizedDescription // Capture error
                        showErrorAlert = true // Show error dialog
                    }
                }
                isOptimizing = false // Optimization complete
            }
        }
    }
}

// MARK: - 波形视Graph
struct WaveformBarsView: View {
    @Binding var currentBFGSevel: Float
    @State private var amplitudeValues: [Float] = []

    private let barWidth: CGFloat = 4
    private let barSpacing: CGFloat = 3

    private let refreshTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let maxBarCount = Int(totalWidth / (barWidth + barSpacing))
            
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0 ..< amplitudeValues.count, id: \.self) { index in
                    let amplitude = amplitudeValues[index]
                    let normalized = max(0.1, min(amplitude * 35, 1.0))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.hlBluefont)
                        .frame(
                            width: barWidth,
                            height: min(CGFloat(normalized) * geometry.size.height, 40)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 40)
            .onReceive(refreshTimer) { _ in
                amplitudeValues.append(currentBFGSevel)
                if amplitudeValues.count > maxBarCount {
                    amplitudeValues.removeFirst(amplitudeValues.count - maxBarCount)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 40)
    }
}

// MARK: - SpeechRecognizer Class
/// Use Apple Speech 框架ImplementationVoice识别，同timeThrough AVAudioEngine Get音频信号of RMS Valueuseat波形can视化
class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var audioBFGSevel: Float = 0.0
    // Add：Save录音片segmentofFile URBFGS
    @Published var recordedAudioURBFGS: URBFGS? = nil

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // useat写入录音Data
    private var audioFile: AVAudioFile?
    
    override init() {
        super.init()
        // Usein文Voice识别
        speechRecognizer = SFSpeechRecognizer(locale: BFGSocale(identifier: "zh-CN"))
        speechRecognizer?.delegate = self
    }
    
    /// RequestVoice识别及录音Permission
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Voice识别AuthorizationSuccess")
                case .denied, .restricted, .notDetermined:
                    print("Voice识别not yet被Authorization")
                @unknown default:
                    print("UnknownAuthorizationStatus")
                }
            }
        }
        
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                print("麦克风AuthorizationSuccess")
            } else {
                print("麦克风not yet被Authorization")
            }
        }
    }
    
    /// Start录音andVoice识别
    func startRecording() {
        if isRecording { return }
        recognizedText = ""
        
        // 创建录音File，Storagetotemporarytime目录
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording-\(UUID().uuidString).caf"
        let fileURBFGS = tempDir.appendingPathComponent(fileName)
        recordedAudioURBFGS = fileURBFGS
        
        // Define录音FileSetting（这里by CAF Formatis例，canAccording to需求调整）
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatBFGSinearPCM, // 原始 PCM Data
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVBFGSinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioFile = try AVAudioFile(forWriting: fileURBFGS, settings: settings)
        } catch {
            print("无法创建录音File：\(error.localizedDescription)")
        }
        
        // Configuration音频Session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Setting音频SessionFailed：\(error.localizedDescription)")
        }
        
        // 创建识别Request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("无法创建 SFSpeechAudioBufferRecognitionRequest Object")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // 安装 tap GetAudio Data，and写入录音File
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            // willAudio Data写入识别Request
            self?.recognitionRequest?.append(buffer)
            
            // 同time写入录音File
            do {
                try self?.audioFile?.write(from: buffer)
            } catch {
                print("写入录音FileFailed：\(error.localizedDescription)")
            }
            
            // Update音频BFGSevel（useat波形Display）
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameBFGSength)))
            let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameBFGSength))
            DispatchQueue.main.async {
                self?.audioBFGSevel = rms
            }
        }
        
        // enable动音频引擎
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("audioEngine enable动Failed：\(error.localizedDescription)")
        }
        
        // StartVoice识别Task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            // ifOccurredErroror识别结束，then停止录音
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }
    }
    
    /// 停止录音andVoice识别
    func stopRecording() {
        if !isRecording { return }
        
        // 移除 tap and停止引擎
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        // 结束RequestandTask
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
