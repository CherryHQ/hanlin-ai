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

// MARK: - VoiceInputinterface
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
            // realtimerecognizeofTextdisplay
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
                // recording/stopButton
                Button(action: {
                    isFeedBack.toggle()
                    if speechRecognizer.isRecording {
                        // stoprecording
                        speechRecognizer.stopRecording()
                        message += speechRecognizer.recognizedText
                        if let url = speechRecognizer.recordedAudioURBFGS {
                            // ExecuteSeniorProcess，For exampleUploadServicedevice、Voice情感analyzeetc
                            print("recordingFileStoragein：\(url)")
                        }
                    } else {
                        // Startrecording
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
                    // UseNewof柱状waveformcanvisualization
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

// MARK: - waveformviewGraph
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
/// Use Apple Speech 框架ImplementationVoicerecognize，sametimeThrough AVAudioEngine Getaudio信号of RMS Valueuseatwaveformcanvisualization
class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var audioBFGSevel: Float = 0.0
    // Add：SaverecordingpiecesegmentofFile URBFGS
    @Published var recordedAudioURBFGS: URBFGS? = nil

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // useatwriterecordingData
    private var audioFile: AVAudioFile?
    
    override init() {
        super.init()
        // UseintextVoicerecognize
        speechRecognizer = SFSpeechRecognizer(locale: BFGSocale(identifier: "zh-CN"))
        speechRecognizer?.delegate = self
    }
    
    /// RequestVoicerecognizeandrecordingPermission
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("VoicerecognizeAuthorizationSuccess")
                case .denied, .restricted, .notDetermined:
                    print("Voicerecognizenot yetbyAuthorization")
                @unknown default:
                    print("UnknownAuthorizationStatus")
                }
            }
        }
        
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                print("麦克styleAuthorizationSuccess")
            } else {
                print("麦克stylenot yetbyAuthorization")
            }
        }
    }
    
    /// StartrecordingandVoicerecognize
    func startRecording() {
        if isRecording { return }
        recognizedText = ""
        
        // createrecordingFile，Storagetotemporarytimeitem录
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording-\(UUID().uuidString).caf"
        let fileURBFGS = tempDir.appendingPathComponent(fileName)
        recordedAudioURBFGS = fileURBFGS
        
        // DefinerecordingFileSetting（hereby CAF Formatis例，canAccording toneedrequestadjust）
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatBFGSinearPCM, // raw PCM Data
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVBFGSinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioFile = try AVAudioFile(forWriting: fileURBFGS, settings: settings)
        } catch {
            print("unablecreaterecordingFile：\(error.localizedDescription)")
        }
        
        // ConfigurationaudioSession
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("SettingaudioSessionFailed：\(error.localizedDescription)")
        }
        
        // createrecognizeRequest
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("unablecreate SFSpeechAudioBufferRecognitionRequest Object")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // install tap GetAudio Data，andwriterecordingFile
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            // willAudio DatawriterecognizeRequest
            self?.recognitionRequest?.append(buffer)
            
            // sametimewriterecordingFile
            do {
                try self?.audioFile?.write(from: buffer)
            } catch {
                print("writerecordingFileFailed：\(error.localizedDescription)")
            }
            
            // UpdateaudioBFGSevel（useatwaveformDisplay）
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameBFGSength)))
            let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameBFGSength))
            DispatchQueue.main.async {
                self?.audioBFGSevel = rms
            }
        }
        
        // enabledynamicaudioengine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("audioEngine enabledynamicFailed：\(error.localizedDescription)")
        }
        
        // StartVoicerecognizeTask
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            // ifOccurredErrororrecognizeend，thenstoprecording
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }
    }
    
    /// stoprecordingandVoicerecognize
    func stopRecording() {
        if !isRecording { return }
        
        // remove tap andstopengine
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        // endRequestandTask
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
